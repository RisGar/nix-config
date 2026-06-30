{
  mkStat,
  mkTimeseries,
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
      # scalar(): an ungrouped count() has an empty labelset and would not match
      # node_load1{instance,job}, which made this panel render "no data"
      expr = "100 * node_load1 / scalar(count(node_cpu_seconds_total{mode=\"idle\"}))";
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
      # Neither disk exposes SMART health here: sda is a QEMU/virtio disk and sdb
      # is USB (the bridge doesn't pass SMART through), so smart_status is never
      # emitted. smartctl's exit status is what is actually available.
      expr = "max(smartctl_device_smartctl_exit_status)";
      x = 18;
      y = 0;
      mappings = [
        {
          type = "value";
          options = {
            "0" = {
              text = "ok";
              color = "green";
              index = 0;
            };
            "1" = {
              text = "smartctl failed";
              color = "red";
              index = 1;
            };
          };
        }
      ];
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
      # no disk on this host reports a temperature (virtio + USB), I/O
      # utilisation is the useful signal instead
      title = "Disk I/O utilisation";
      y = 11;
      unit = "percent";
      targets = [
        {
          expr = "rate(node_disk_io_time_seconds_total{device=~\"sd[a-z]+\"}[5m]) * 100";
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
