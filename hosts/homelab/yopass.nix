{ config, ... }:
{


  services.memcached = {
    enable = true;
  };

  virtualisation.oci-containers.containers.yopass = {
    image = "jhaals/yopass";
    environment = {
      TRUSTED_PROXIES = config.apps."pass".hostname;
      PORT = toString config.apps."pass".port;
      DISABLE_FEATURES = "true";
      DISABLE_UPLOAD = "true";
      METRICS_PORT = "9144";
    };
    cmd = [
      "--memcached=127.0.0.1:11211"
    ];
    networks = [
      "host"
    ];
  };

  apps."pass" = {
    port = 8282;

  };
}
