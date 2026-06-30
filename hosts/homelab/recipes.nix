{ config, ... }:

let
  tandoorPort = config.apps."recipes".port;
in
{


  services.tandoor-recipes = {
    enable = true;
    port = tandoorPort;
    # address = "0.0.0.0";
    database.createLocally = true;
    extraConfig = {

      SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
      SOCIALACCOUNT_LOGIN_ON_GET = "1";
      SOCIALACCOUNT_EMAIL_AUTHENTICATION = "1";
      SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = "1";

      ENABLE_SIGNUP = "0";
      HIDE_LOGIN_FORM = "1";
      SOCIAL_DEFAULT_ACCESS = "1";
      ALLOWED_HOSTS = config.apps."recipes".hostname;

      ALLAUTH_TRUSTED_PROXY_COUNT = "1";
    };
  };

  systemd.services.tandoor-recipes.serviceConfig.EnvironmentFile = [
    config.sops.secrets.tandoor.path
  ];

  apps."recipes" = {
    port = 8082;

    content = ''
      handle_path /media/* {
        root * /var/lib/tandoor-recipes/recipes/media
        file_server
      }
      handle_path /static/* {
        root * /var/lib/tandoor-recipes/recipes/static
        file_server
      }
      handle {
        reverse_proxy 127.0.0.1:${toString config.apps."recipes".port}
      }
    '';
  };

  users.users.caddy.extraGroups = [ "tandoor_recipes" ];

}
