{ config, ... }:

let
  tandoorPort = config.ports.tandoor;
in
{
  ports.tandoor = 8082;

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
      ALLOWED_HOSTS = "recipes.rishab.org";

      ALLAUTH_TRUSTED_PROXY_COUNT = "1";
    };
  };

  systemd.services.tandoor-recipes.serviceConfig.EnvironmentFile = [
    config.age.secrets.tandoor.path
  ];

  # Based on https://github.com/TandoorRecipes/recipes/blob/develop/http.d/Recipes.conf.template
  services.caddy.virtualHosts."recipes.rishab.org".extraConfig = ''
    handle_path /media/* {
      root * /var/lib/tandoor-recipes/recipes/media
      file_server
    }

    reverse_proxy 127.0.0.1:${toString config.ports.tandoor}
  '';

  users.users.caddy.extraGroups = [ "tandoor_recipes" ];

}
