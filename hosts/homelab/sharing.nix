{ config, ... }:
{

  apps."pass" = {
    port = 8282;
  };
  services.yopass = {
    enable = true;
    settings = {
      TRUSTED_PROXIES = config.apps."pass".hostname;
      PORT = toString config.apps."pass".port;
      DISABLE_FEATURES = "true";
      DISABLE_UPLOAD = "true";
      METRICS_PORT = "9144";
    };
  };

}
