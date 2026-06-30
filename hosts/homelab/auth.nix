{
  config,
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

  apps = {
    "auth" = {
      port = 1441;
    };
  };

}
