{
  config,
  pkgs,
  lib,
  ...
}:
let
  appCfg = config.apps;
in
{

  services.pocket-id = {
    enable = true;
    settings = {
      ANALYTICS_DISABLED = true;
      APP_URL = "https://${appCfg."auth".hostname}";
      TRUST_PROXY = true;
      PORT = appCfg."auth".port;
      HOST = "127.0.0.1";
    };
    environmentFile = config.sops.secrets.pocket-id.path;
  };

  services.tinyauth = {
    enable = true;
    settings = {
      APPURL = "https://${appCfg."proxy".hostname}";

      ANALYTICS_ENABLED = false;

      SERVER_PORT = appCfg."proxy".port;
      SERVER_ADDRESS = "127.0.0.1";

      AUTH_TRUSTEDPROXIES = "127.0.0.1";

      OAUTH_AUTOREDIRECT = "pocketid";
      OAUTH_PROVIDERS_POCKETID_CLIENTID = "42d56c29-497e-4896-81af-bc2a23144434";
      OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
      OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "https://${appCfg."proxy".hostname}/api/oauth/callback/pocketid";
      OAUTH_PROVIDERS_POCKETID_AUTHURL = "https://${appCfg."auth".hostname}/authorize";
      OAUTH_PROVIDERS_POCKETID_TOKENURL = "https://${appCfg."auth".hostname}/api/oidc/token";
      OAUTH_PROVIDERS_POCKETID_USERINFOURL = "https://${appCfg."auth".hostname}/api/oidc/userinfo";
      OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";

      UI_TITLE = "rishab's auth proxy";
      UI_BACKGROUNDIMAGE = "/background-custom.jpg"; # TODO
    }
    // lib.concatMapAttrs (name: site: {
      "APPS_${lib.toUpper name}_CONFIG_DOMAIN" = site.hostname;
      "APPS_${lib.toUpper name}_OAUTH_GROUPS" = "admin";
    }) (lib.filterAttrs (n: v: v.adminOnly) appCfg);
    environmentFile = config.sops.secrets.tinyauth.path;
  };

  apps = {
    "auth" = {
      port = 1441;
    };
    "proxy" = {
      port = 3011;
      # TODO
      content = ''
        handle /background.jpg {
          root * ${
            pkgs.runCommand "tinyauth-bg" { } "mkdir -p $out && cp ${./background.jpg} $out/background.jpg"
          }
          file_server
        }
        handle {
          reverse_proxy 127.0.0.1:${toString appCfg."proxy".port}
        }
      '';
    };
  };

}
