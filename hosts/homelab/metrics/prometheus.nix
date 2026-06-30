{ config, lib, ... }:
let
  # Every app vhost that actually proxies to a backend, probed over the public
  # URL: unit state alone would not catch a broken Caddyfile or a 500.
  # (proxmox is left out — self-signed, so the TLS check would always fail.)
  probeTargets = lib.mapAttrsToList (_: app: "https://${app.hostname}") (
    lib.filterAttrs (_: app: app.port != null && app.hostname != null) config.apps
  );

  exporterTarget = name: "127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}";
in
{
  services.prometheus = {
    enable = true;
    port = 9090;

    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9002;
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
        job_name = "blackbox";
        metrics_path = "/probe";
        params.module = [ "http_2xx" ];
        static_configs = [ { targets = probeTargets; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = exporterTarget "blackbox";
          }
        ];
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
