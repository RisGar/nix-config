{ ... }:
{
  # All of these are scraped by Prometheus over 127.0.0.1 only. The module
  # default is 0.0.0.0, which needlessly exposes them to every local process
  # (and to containers reaching the host gateway).
  services.prometheus.exporters = {
    postgres = {
      enable = true;
      listenAddress = "127.0.0.1";
      # server-wide queries (pg_database / pg_stat_database) for every database
      runAsLocalSuperUser = true;
    };

    # immich's cache; dawarich's instance would need a second exporter
    redis = {
      enable = true;
      listenAddress = "127.0.0.1";
      user = "redis-immich";
      group = "redis-immich";
      extraFlags = [ "--redis.addr=unix:///run/redis-immich/redis.sock" ];
    };

    smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
      devices = [
        "/dev/sda" # system
        "/dev/sdb" # 4.5T data disk
      ];
      maxInterval = "10m";
    };
  };
}
