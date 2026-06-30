{
  config,
  lib,
  pkgs,
  ...
}:

{

  networking = {
    nat = {
      enable = true;
      internalInterfaces = [
        "ve-+"
        "wg0"
      ];
      externalInterface = "ens18";
    };

    # Wireguard
    # firewall.allowedUDPPorts = [ 51820 ];
    # wireguard.interfaces.wg0 = {
    #   ips = [ "10.100.0.1/24" ]; # Internal subnet for VPN tunnel listenPort = 51820;
    #
    #   privateKeyFile = config.age.secrets.wg-private.path;
    #
    #   peers = [
    #     {
    #       publicKey = "ZtTIrOhZlxnTawrOR94AIzsnU21Izu1Q0pB9ZDhGQBA=";
    #       allowedIPs = [ "10.100.0.2/32" ];
    #     }
    #   ];
    # };
  };

  # Layer 7: Caddy Reverse Proxy
  services.caddy = {
    enable = true;
    extraConfig = ''
      (tinyauth_forwarder) {
        forward_auth 127.0.0.1:${toString config.ports.tinyauth} {
          uri /api/auth/caddy
          copy_headers Remote-User Remote-Name Remote-Email Remote-Groups
        }
      }

      (require_admin) {
        @notAdmin {
          not header_regexp Remote-Groups \badmin\b
        }
        respond @notAdmin "You do not have the permission to access this service." 403
      }
    '';
    virtualHosts = {
      "test.rishab.org".extraConfig = ''
        import tinyauth_forwarder
        respond "Hello {http.request.header.Remote-User}" 200
      '';
      "proxmox.rishab.org".extraConfig = ''
        import tinyauth_forwarder
        import require_admin

        reverse_proxy https://192.168.178.25:8006 {
          transport http {
            tls_insecure_skip_verify
          }
        }
      '';
    };
  };

  # Layer 4: Rathole Client
  services.rathole = {
    enable = true;
    role = "client";
    settings = {
      client = {
        remote_addr = "85.215.138.48:2333";
        transport = {
          type = "noise";
          noise = {
            pattern = "Noise_KK_25519_ChaChaPoly_BLAKE2s";
          };
        };
        services = {
          # Route incoming VPS port 80 to the local Caddy port 80 (needed for Let's Encrypt HTTP-01 challenge)
          http_passthrough = {
            local_addr = "127.0.0.1:80";
          };
          # Route incoming VPS port 443 to the local Caddy port 443
          https_passthrough = {
            local_addr = "127.0.0.1:443";
          };
          # # Route incoming VPS WireGuard traffic to the local WireGuard port
          # wireguard_passthrough = {
          #   local_addr = "127.0.0.1:51820";
          #   type = "udp";
          # };
        };
      };
    };
  };

  assertions = [
    {
      assertion =
        let
          portValues = lib.map lib.toString (lib.attrValues config.ports);
          uniquePorts = lib.unique portValues;
        in
        lib.length portValues == lib.length uniquePorts;
      message = "Overlapping ports detected in config.ports! Please ensure all ports are unique.";
    }
  ];

}
