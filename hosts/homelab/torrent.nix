{
  config,
  ...
}:
let
  # We save the outer host config to a variable so we can access your custom ports inside the container's configuration scope without conflicts.
  portsConfig = config.ports;
in
{
  ports.transmission = 9091;

  containers.transmission-vpn = {
    autoStart = false; # TODO
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    enableTun = true; # Required for Wireguard

    bindMounts = {
      # Your download directory
      "/completed" = {
        hostPath = "/mnt/external/Library";
        isReadOnly = false;
      };
      # Your transmission config/state directory
      "/var/lib/transmission" = {
        hostPath = "/var/lib/transmission";
        isReadOnly = false;
      };
      # Mount your secret file directly into the container securely
      "/etc/nordvpn-token" = {
        hostPath = config.age.secrets.nordvpn.path;
        isReadOnly = true;
      };
    };

    config =
      { lib, pkgs, ... }:
      {
        # 1. Add the wgnord package and required networking tools
        environment.systemPackages = [
          pkgs.wgnord
          pkgs.wireguard-tools
        ];

        # 2. Create a systemd service to run wgnord connect on boot
        systemd.services.wgnord-connect = {
          description = "Connect to best NordVPN server via wgnord";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          # wgnord needs these in its PATH to run successfully
          path = [
            pkgs.wgnord
            pkgs.wireguard-tools
            pkgs.curl
            pkgs.jq
            pkgs.iproute2
            pkgs.iptables
            pkgs.bash
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Login automatically using the token from your age secret, then connect to Germany (DE)
            ExecStartPre = "${lib.getExe pkgs.bash} -c '${lib.getExe pkgs.wgnord} login $(cat /etc/nordvpn-token)'";
            ExecStart = "${lib.getExe pkgs.wgnord} connect de";
            ExecStop = "${lib.getExe pkgs.wgnord} disconnect";
          };
        };

        # 3. Setup Transmission
        services.transmission = {
          enable = true;
          openRPCPort = true;
          settings = {
            download-dir = "/completed";

            rpc-bind-address = "0.0.0.0";
            rpc-port = portsConfig.transmission;

            # Allow Caddy's domain
            rpc-host-whitelist = "torrent.rishab.org";

            rpc-whitelist-enabled = false; # Disable IP checking since our NixOS firewall handles it

          };
        };

        # 4. Ensure transmission ONLY runs if wgnord has successfully connected
        systemd.services.transmission.after = [ "wgnord-connect.service" ];
        systemd.services.transmission.bindsTo = [ "wgnord-connect.service" ];

        # 5. Built-in Killswitch: Drop everything not going over the NordLynx tunnel, except local LAN/Host
        networking.firewall.enable = true;
        networking.firewall.extraCommands = ''
          # Allow traffic from the container to your host (192.168.100.10) - Required for Caddy
          iptables -A OUTPUT -o eth0 -d 192.168.100.10 -j ACCEPT
          # Allow traffic from the container to your physical local network
          iptables -A OUTPUT -o eth0 -d 192.168.178.0/24 -j ACCEPT
          # DROP any other traffic on eth0. If wgnord drops, the internet is cut!
          iptables -A OUTPUT -o eth0 -j DROP
        '';

        system.stateVersion = "26.05";
      };
  };

  services.caddy.virtualHosts."torrent.rishab.org".extraConfig = ''
    @has_auth {
      header Authorization Basic*
    }

    handle @has_auth {
      basicauth argon2id {
      }
      reverse_proxy 192.168.100.11:${toString config.ports.transmission}
    }

    handle {
      import tinyauth_forwarder
      import require_admin
      reverse_proxy 192.168.100.11:${toString config.ports.transmission}
    }
  '';
}
