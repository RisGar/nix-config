{
  config,
  lib,
  pkgs,
  ...
}:
let
  appCfg = config.apps;
  tUid = toString config.ids.uids.transmission;
  tGid = toString config.ids.gids.transmission;

  vpnNetns = "vpn";
  vethHost = "10.200.200.1";
  vethNetns = "10.200.200.2";
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/transmission 0755 ${tUid} ${tGid} - -"
  ];

  # 1. Setup the network namespace and veth pair for Caddy -> Transmission communication
  systemd.services.netns-vpn = {
    description = "VPN Network Namespace";
    before = [
      "nordvpn-connect.service"
      "transmission.service"
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.iproute2
      pkgs.coreutils
    ];
    script = ''
      # Create namespace if it doesn't exist
      ip netns add ${vpnNetns} || true
      ip netns exec ${vpnNetns} ip link set lo up

      # Create resolv.conf for the namespace
      mkdir -p /etc/netns/${vpnNetns}
      echo "nameserver 103.86.96.100" > /etc/netns/${vpnNetns}/resolv.conf
      echo "nameserver 103.86.99.100" >> /etc/netns/${vpnNetns}/resolv.conf

      # Create veth pair for host-to-netns communication
      ip link add veth-vpn type veth peer name veth-host || true
      
      # Move veth-host into the namespace
      ip link set veth-host netns ${vpnNetns} || true

      # Configure host side
      ip addr add ${vethHost}/24 dev veth-vpn || true
      ip link set veth-vpn up || true

      # Configure namespace side
      ip netns exec ${vpnNetns} ip addr add ${vethNetns}/24 dev veth-host || true
      ip netns exec ${vpnNetns} ip link set veth-host up || true
    '';
    preStop = ''
      ip link del veth-vpn || true
      ip netns del ${vpnNetns} || true
    '';
  };

  # 2. Connect to NordVPN using WireGuard, injecting the interface into the namespace
  systemd.services.nordvpn-connect = {
    description = "connecting to best nordvpn server";
    # wantedBy = [ "multi-user.target" ];
    after = [
      "netns-vpn.service"
      "network-online.target"
    ];
    wants = [
      "netns-vpn.service"
      "network-online.target"
    ];
    bindsTo = [ "netns-vpn.service" ];

    path = [
      pkgs.wireguard-tools
      pkgs.curl
      pkgs.jq
      pkgs.bash
      pkgs.coreutils
      pkgs.openresolv
      pkgs.iproute2
    ];

    script = ''
      set -eo pipefail
      TOKEN="$(cat ${config.sops.secrets.nordvpn.path})"
      B64_TOKEN="$(printf "token:%s" "$TOKEN" | base64 -w 0)"

      echo "Fetching credentials from NordVPN..."
      while true; do
        CREDS=$(curl -4 -sSf -H "User-Agent: NordApp Linux 3.16.1 Linux 5.4.0-58-generic" \
          "https://api.nordvpn.com/v1/users/services/credentials" \
          -H "Content-Type: application/json" \
          -H "Authorization: Basic $B64_TOKEN" || true)
        if [ -n "$CREDS" ]; then
          break
        fi
        echo "Network not ready, retrying in 5 seconds..."
        sleep 5
      done

      PRIVKEY=$(echo "$CREDS" | jq -r '.nordlynx_private_key')

      echo "Fetching best server..."
      SERVER=$(curl -4 -sSf "https://api.nordvpn.com/v1/servers/recommendations?limit=1&filters\[servers_groups\]\[identifier\]=legacy_p2p")
      SERVER_IP=$(echo "$SERVER" | jq -r '.[0].station')
      SERVER_PUBKEY=$(echo "$SERVER" | jq -r '.[0].technologies[] | select(.identifier=="wireguard_udp").metadata[] | select(.name=="public_key").value')

      # Cleanup existing interface if any
      ip netns exec ${vpnNetns} ip link del nordlynx 2>/dev/null || true
      ip link del nordlynx 2>/dev/null || true

      echo "Creating wireguard interface..."
      # Create wireguard interface on host so it uses host routing for encrypted packets
      ip link add nordlynx type wireguard

      # Move it to the namespace
      ip link set nordlynx netns ${vpnNetns}

      echo "Configuring wireguard inside namespace..."
      # Configure it inside the namespace
      ip netns exec ${vpnNetns} wg set nordlynx \
        private-key <(echo "$PRIVKEY") \
        peer "$SERVER_PUBKEY" \
        allowed-ips 0.0.0.0/0,::/0 \
        endpoint "$SERVER_IP:51820" \
        persistent-keepalive 25

      # The Address assigned by NordVPN is usually 10.5.0.2
      ip netns exec ${vpnNetns} ip addr add 10.5.0.2/32 dev nordlynx
      ip netns exec ${vpnNetns} ip link set nordlynx up

      echo "Setting default route..."
      # Route all traffic in the namespace through the VPN
      ip netns exec ${vpnNetns} ip route add default dev nordlynx

      echo "WireGuard is up. Keeping service alive..."
      # exec sleep infinity
    '';

    preStop = ''
      ip netns exec ${vpnNetns} ip link del nordlynx || true
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Restart = "on-failure";
      # RestartSec = "5s";
    };
  };

  # 3. Setup Transmission on the host but constrain it to the VPN namespace
  services.transmission = {
    enable = true;
    openRPCPort = true;
    settings = {
      download-dir = "/mnt/external/Library";

      # Bind to all interfaces inside the namespace
      rpc-bind-address = "0.0.0.0";
      rpc-port = appCfg."torrent".port;

      # allow Caddy's domain
      rpc-host-whitelist = config.apps."torrent".hostname;

      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1,${vethHost}"; # allow localhost and host proxy

      encryption = 2; # strictly require encrypted peer connections
      lpd-enabled = false; # prevent multicast spam on your local network
    };
  };

  systemd.services.transmission = {
    # wantedBy = [ "multi-user.target" ];
    after = [ "nordvpn-connect.service" ];
    bindsTo = [ "nordvpn-connect.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${vpnNetns}";
      BindReadOnlyPaths = [ "/etc/netns/${vpnNetns}/resolv.conf:/etc/resolv.conf" ];
      PrivateNetwork = lib.mkForce false; # don't use systemd's PrivateNetwork, use our namespace
      ReadWritePaths = [ "/mnt/external/Library" ];
      # RootDirectory = lib.mkForce "";
      # RootDirectoryStartOnly = lib.mkForce false;
      # Restart = lib.mkForce "on-failure";
      # RestartSec = lib.mkForce "10s";
    };
  };

  # 4. Expose WebUI via Caddy
  apps."torrent" = rec {
    port = 9091;
    adminOnly = true;
    content = ''
      @has_auth {
        header Authorization Basic*
      }

      handle @has_auth {
        basicauth argon2id {
          rishab $argon2id$v=19$m=47104,t=1,p=1$gBT09qm8aNM7Hr4SQZENHg$3CAoTQzS3BDoc/7XthdS0T61tkKGj/GYlMa26kf8Pfg
        }
        reverse_proxy ${vethNetns}:${toString port}
      }

      handle {
        import tinyauth_forwarder
        reverse_proxy ${vethNetns}:${toString port}
      }
    '';
  };
}
