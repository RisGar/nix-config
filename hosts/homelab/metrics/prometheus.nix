{ config, ... }:
let
  exporterTarget = name: "127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}";
in
{
  services.prometheus = {
    enable = true;
    port = 9090;
    # Only Caddy reaches this (through the metrics vhost) and only Prometheus
    # reaches the exporters, both from localhost.
    listenAddress = "127.0.0.1";

    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9002;
      listenAddress = "127.0.0.1";
    };

    # Exporters themselves are enabled in ./exporters.nix; the ports are read
    # back from their options so the two files cannot drift apart.
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ]; } ];
      }
      {
        job_name = "node";
        static_configs = [ { targets = [(exporterTarget "node")]; } ];
      }
      {
        job_name = "yopass";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.yopass.settings.METRICS_PORT}" ]; } ];
      }
      {
        job_name = "caddy";
        static_configs = [ { targets = [ "127.0.0.1:2019" ]; } ];
      }
      {
        job_name = "cloudflared";
        static_configs = [ { targets = [ "127.0.0.1:20241" ]; } ];
      }
      {
        job_name = "postgres";
        static_configs = [ { targets = [ (exporterTarget "postgres") ]; } ];
      }
      {
        job_name = "redis";
        static_configs = [ { targets = [ (exporterTarget "redis") ]; } ];
      }
      {
        job_name = "smartctl";
        static_configs = [ { targets = [ (exporterTarget "smartctl") ]; } ];
      }
    ];
  };
}
