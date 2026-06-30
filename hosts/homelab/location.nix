{ config, lib, ... }: {

  apps."timeline" = {
    port = config.services.dawarich.webPort;
  };
  services.dawarich = {
    enable = true;
    webPort = 3035;
    localDomain = config.apps."timeline".hostname;
    configureNginx = false; # Use Caddy instead
    environment = {
      OIDC_CLIENT_ID = "1e0d3045-db40-4ea5-b88b-c42a00119a4d";
      OIDC_ISSUER = "https://auth.rishab.org";
      OIDC_REDIRECT_URI = "https://${config.apps."timeline".hostname}/users/auth/openid_connect/callback";
      OIDC_PROVIDER_NAME = "Pocket ID";
      OIDC_AUTO_REGISTER = "true";
      OIDC_PKCE_ENABLED = "true";
      ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
      ALLOW_EMAIL_PASSWORD_LOGIN = "false";
    };
    extraEnvFiles = [ config.sops.secrets.dawarich.path ];
  };
}
