{
  config,
  lib,
  ...
}@args:
{
  options.apps = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, name, ... }: {
          options = {
            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "${name}.${args.config.vars.FQDN}";
            };
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
            };
            socket = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            forwardAuth = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            adminOnly = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            content = lib.mkOption {
              type = lib.types.str;
              default =
                if config.port != null then
                  "reverse_proxy 127.0.0.1:${toString config.port}"
                else if config.socket != null then
                  "reverse_proxy unix//${config.socket}"
                else
                  "";
            };
          };

        }
      )
    );
    default = { };
  };

  config = {
    vars.FQDN = "rishab.org";

    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
        metrics
        servers {
          trusted_proxies_unix
        }
      '';
      extraConfig = ''
        (tinyauth_forwarder) {
          forward_auth 127.0.0.1:${toString config.apps."proxy".port} {
            uri /api/auth/caddy
            copy_headers Remote-User Remote-Name Remote-Email Remote-Groups
          }
        }
      '';
      virtualHosts =
        let
          hostsWithNames = lib.filterAttrs (n: v: v.hostname != null) config.apps;
        in
        lib.mapAttrs' (
          name: site:
          lib.nameValuePair "http://${site.hostname}" {
            listenAddresses = [ "unix//run/caddy/caddy.sock|0660" ];
            extraConfig = ''
              ${lib.optionalString site.forwardAuth "import tinyauth_forwarder"}
              ${site.content}
            '';
          }
        ) hostsWithNames;
    };

    apps = {
      "test" = {
        forwardAuth = true;
        content = ''
          respond "Hello {http.request.header.Remote-User}." 200
        '';
      };
      "proxmox" = {
        forwardAuth = true;
        adminOnly = true;
        content = ''
          reverse_proxy https://192.168.178.25:8006 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "homelab-tunnel" = {
          credentialsFile = config.sops.secrets.cloudflared-creds.path;
          default = "unix:/run/caddy/caddy.sock";
          ingress = {
            "ssh.${config.vars.FQDN}" = "ssh://localhost:22";
          };
        };
      };
    };

    systemd.services.caddy.serviceConfig.RuntimeDirectory = "caddy";
    systemd.services.cloudflared-tunnel-homelab-tunnel.serviceConfig.SupplementaryGroups = [ "caddy" ];

    assertions = [
      {
        assertion =
          let
            vhosts = lib.attrValues config.apps;
            portValues = lib.map (v: lib.toString v.port) (lib.filter (v: v.port != null) vhosts);
            uniquePorts = lib.unique portValues;
          in
          lib.length portValues == lib.length uniquePorts;
        message = "overlapping ports detected in config.apps! please ensure all ports are unique.";
      }
      {
        assertion =
          let
            vhosts = lib.attrValues config.apps;
          in
          builtins.all (
            app:
            if app.port != null then
              app.socket == null
            else if app.socket != null then
              app.port == null
            else
              true
          ) vhosts;
        message = "port and socket declared at the same time in config.apps! please only declare one of them.";
      }
      # TODO: check that port and socket isn't both declared
    ];
  };
}
