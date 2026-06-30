{ config, ... }:
{
  ports.yopass = "8282";

  services.memcached = {
    enable = true;
  };

  virtualisation.oci-containers.containers.yopass = {
    image = "jhaals/yopass";
    environment = {
      TRUSTED_PROXIES = "pass.rishab.org";
      PORT = config.ports.yopass;
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

  services.caddy.virtualHosts."pass.rishab.org".extraConfig =
    "reverse_proxy 127.0.0.1:${toString config.ports.yopass}";
}
