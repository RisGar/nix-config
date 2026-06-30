{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  inherit (config.vars) FQDN;

  # Pocket ID OIDC client used by Caddy for authentication.
  # Its callback URLs must include https://*.${FQDN}/oauth2/callback
  oidcClientId = "42d56c29-497e-4896-81af-bc2a23144434";

  # Caddyfile snippet to inject for each `apps.<name>.access` value.
  oidcSnippets = {
    authenticated = "oidc_auth";
    admin = "oidc_admin";
  };
in
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
            access = lib.mkOption {
              type = lib.types.enum [
                "public"
                "authenticated"
                "admin"
              ];
              default = "public";
              description = ''
                Who may reach this vhost.

                - `public`: no `oidc` handler is added, `content` is served as is.
                  Use this for apps that make their own per-request auth decisions.
                - `authenticated`: any signed-in Pocket ID user.
                - `admin`: only members of the Pocket ID `admin` group.

                Authentication happens in-process via the caddy-oidc plugin, so
                `admin` always implies `authenticated`.
              '';
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
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/relvacode/caddy-oidc@v0.4.3" ];
        hash = "sha256-YcoOyjE4mgMy1JtSYMRMCZVDPASVNUPfi6vNzNWfXho=";
      };
      environmentFile = config.sops.secrets.caddy-oidc.path;
      globalConfig = ''
        auto_https off
        metrics
        servers {
          trusted_proxies_unix
        }

        oidc {
          issuer https://${config.apps."auth".hostname}
          client_id ${oidcClientId}
          client_secret {env.OIDC_CLIENT_SECRET}
          scope openid email profile groups
          username preferred_username
          protected_resource_metadata off

          # The session cookie is scoped to the parent domain so a single login
          # covers every vhost. `groups` is copied into the session because the
          # access rules below match on it.
          authenticate cookie {
            name caddy_session
            secret {env.OIDC_COOKIE_SECRET}
            domain ${FQDN}
            same_site lax
            claim groups
            max_age 168h
          }
        }
      '';
      extraConfig = ''
        # Any authenticated Pocket ID user.
        (oidc_auth) {
          oidc {
            allow {
              user *
            }
          }
        }

        # Members of the `admin` group only. Anything else (including anonymous
        # visitors, who trip the implicit deny and get redirected to Pocket ID)
        # is rejected.
        (oidc_admin) {
          oidc {
            allow {
              user *
              claim groups admin
            }
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
              ${lib.optionalString (site.access != "public") "import ${oidcSnippets.${site.access}}"}
              ${site.content}
            '';
          }
        ) hostsWithNames;
    };

    apps = {
      "test" = {
        access = "authenticated";
        content = ''
          respond "Hello {http.auth.user.id}." 200
        '';
      };
      "proxmox" = {
        access = "admin";
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
