{ config, ... }:
{ config, pkgs, ... }:
{
  ports.pocket-id = 1441;
  services.pocket-id = {
    enable = true;
    settings = {
      ANALYTICS_DISABLED = true;
      APP_URL = "https://auth.rishab.org";
      TRUST_PROXY = true;
      PORT = config.ports.pocket-id;
      HOST = "127.0.0.1";
    };
    environmentFile = config.age.secrets.pocket-id.path;
  };

  ports.tinyauth = 3011;
  services.tinyauth = {
    enable = true;
    settings = {
      APPURL = "https://proxy.rishab.org";

      ANALYTICS_ENABLED = false;

      SERVER_PORT = config.ports.tinyauth;
      SERVER_ADDRESS = "127.0.0.1";

      AUTH_TRUSTEDPROXIES = "127.0.0.1";

      OAUTH_AUTOREDIRECT = "pocketid";
      OAUTH_PROVIDERS_POCKETID_CLIENTID = "42d56c29-497e-4896-81af-bc2a23144434";
      OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
      OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "https://proxy.rishab.org/api/oauth/callback/pocketid";
      OAUTH_PROVIDERS_POCKETID_AUTHURL = "https://auth.rishab.org/authorize";
      OAUTH_PROVIDERS_POCKETID_TOKENURL = "https://auth.rishab.org/api/oidc/token";
      OAUTH_PROVIDERS_POCKETID_USERINFOURL = "https://auth.rishab.org/api/oidc/userinfo";
      OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";

      UI_TITLE = "rishab's auth proxy";
      UI_BACKGROUNDIMAGE = "/background-custom.jpg";

    };
    # environmentFile = config.age.secrets.tinyauth.path;
  };

  services.caddy.virtualHosts = {
    "auth.rishab.org".extraConfig = "reverse_proxy 127.0.0.1:${toString config.ports.pocket-id}";
    "proxy.rishab.org".extraConfig = ''
      handle /background.jpg {
        root * ${
          pkgs.runCommand "tinyauth-bg" { } "mkdir -p $out && cp ${./background.jpg} $out/background.jpg"
        }
        file_server
      }
      handle {
        reverse_proxy 127.0.0.1:${toString config.ports.tinyauth}
      }
    '';
  };

}
