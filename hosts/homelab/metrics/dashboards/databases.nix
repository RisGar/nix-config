{
  mkStat,
  mkTimeseries,
  okFailedMappings,
  ...
}:
{
  uid = "homelab-databases";
  title = "Databases";
  schemaVersion = 39;
  version = 1;
  refresh = "1m";
  time = {
    from = "now-6h";
    to = "now";
  };
  panels = [
    (mkStat {
      title = "Postgres";
      expr = "min(pg_up)";
      x = 0;
      y = 0;
      mappings = okFailedMappings;
      noValue = "not scraped";
    })
    (mkStat {
      title = "Redis (immich cache)";
      expr = "min(redis_up)";
      x = 6;
      y = 0;
      mappings = okFailedMappings;
      noValue = "not scraped";
    })
    (mkStat {
      title = "Postgres connections";
      expr = "sum(pg_stat_database_numbackends)";
      x = 12;
      y = 0;
    })
    (mkStat {
      title = "Redis memory";
      expr = "max(redis_memory_used_bytes)";
      x = 18;
      y = 0;
      unit = "bytes";
    })
    (mkTimeseries {
      title = "Database size";
      y = 4;
      unit = "bytes";
      targets = [
        {
          expr = "pg_database_size_bytes";
          legend = "{{datname}}";
        }
      ];
    })
    (mkTimeseries {
      title = "Connections per database";
      y = 11;
      targets = [
        {
          expr = "pg_stat_database_numbackends";
          legend = "{{datname}}";
        }
      ];
    })
    (mkTimeseries {
      title = "Cache hit ratio";
      y = 18;
      unit = "percentunit";
      min = 0;
      max = 1;
      targets = [
        {
          expr = "sum by (datname) (rate(pg_stat_database_blks_hit[5m])) / (sum by (datname) (rate(pg_stat_database_blks_hit[5m])) + sum by (datname) (rate(pg_stat_database_blks_read[5m])))";
          legend = "{{datname}}";
        }
      ];
    })
  ];
}
