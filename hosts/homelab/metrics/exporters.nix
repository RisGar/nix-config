{ ... }:
{
  services.prometheus.exporters = {
    blackbox = {
      enable = true;
      configFile = ./blackbox.yml;
    };

    postgres = {
      enable = true;
      # server-wide queries (pg_database / pg_stat_database) for every database
      runAsLocalSuperUser = true;
    };

    # immich's cache; dawarich's instance would need a second exporter
    redis = {
      enable = true;
      user = "redis-immich";
      group = "redis-immich";
      extraFlags = [ "--redis.addr=unix:///run/redis-immich/redis.sock" ];
    };

    smartctl = {
      enable = true;
      devices = [
        "/dev/sda" # system
        "/dev/sdb" # 4.5T data disk
      ];
      maxInterval = "10m";
    };
  };
}
