{
  mkStat,
  mkTimeseries,
  okFailedMappings,
  ...
}:
let
  pctFreeThresholds = [
    {
      color = "red";
      value = null;
    }
    {
      color = "yellow";
      value = 10;
    }
    {
      color = "green";
      value = 20;
    }
  ];
in
{
  uid = "homelab-resources";
  title = "Resources & hardware";
  schemaVersion = 39;
  version = 1;
  refresh = "1m";
  time = {
    from = "now-6h";
    to = "now";
  };
  panels = [
    (mkStat {
      title = "Fullest filesystem";
      expr = "min(100 * node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|ramfs|overlay\"})";
      x = 0;
      y = 0;
      unit = "percent";
      thresholds = pctFreeThresholds;
    })
    (mkStat {
      title = "Memory available";
      expr = "100 * node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes";
      x = 6;
      y = 0;
      unit = "percent";
      thresholds = pctFreeThresholds;
    })
    (mkStat {
      title = "CPU load (1m / cores)";
      expr = "100 * node_load1 / count(node_cpu_seconds_total{mode=\"idle\"})";
      x = 12;
      y = 0;
      unit = "percent";
      thresholds = [
        {
          color = "green";
          value = null;
        }
        {
          color = "yellow";
          value = 100;
        }
        {
          color = "red";
          value = 200;
        }
      ];
    })
    (mkStat {
      title = "Disk health";
      expr = "min(smartctl_device_smart_status)";
      x = 18;
      y = 0;
      mappings = okFailedMappings;
      noValue = "no SMART data";
    })
    (mkTimeseries {
      title = "Filesystem usage";
      y = 4;
      unit = "percent";
      targets = [
        {
          expr = "100 - 100 * node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|ramfs|overlay\"}";
          legend = "{{mountpoint}}";
        }
      ];
    })
    (mkTimeseries {
      title = "Disk temperature";
      y = 11;
      unit = "celsius";
      targets = [
        {
          expr = "smartctl_device_temperature{temperature_type=\"current\"}";
          legend = "{{device}}";
        }
      ];
    })
    (mkTimeseries {
      title = "Network throughput";
      y = 18;
      unit = "bps";
      targets = [
        {
          expr = "rate(node_network_receive_bytes_total{device=\"ens18\"}[5m]) * 8";
          legend = "in";
        }
        {
          expr = "rate(node_network_transmit_bytes_total{device=\"ens18\"}[5m]) * 8";
          legend = "out";
        }
      ];
    })
  ];
}
