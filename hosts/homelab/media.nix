{ config, ... }: {
  apps."media" = {
    port = 8096;
  };
  services.jellyfin = {
    enable = true;
    forceEncodingConfig = true;
  };

  apps."manga" = {
    port = config.services.stump.port;
  };

  services.stump = {
    enable = true;
    environment = {
      STUMP_OIDC_ENABLED = "true";
      STUMP_OIDC_ISSUER_URL = "https://auth.rishab.org";
      STUMP_OIDC_CLIENT_ID = "2531f856-5bab-4fd7-8fd9-adc5a3782a35";
      STUMP_OIDC_DISABLE_LOCAL_AUTH = "true";
      STUMP_TRUST_PROXY_HEADERS = "true";
    };
    secretFiles = {
      STUMP_OIDC_CLIENT_SECRET = config.sops.secrets.stump.path;
    };
  };
}
