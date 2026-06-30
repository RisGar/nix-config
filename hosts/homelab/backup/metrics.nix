{ config, lib, pkgs, ... }:
let
  grafana = import ../../../lib/grafana.nix { inherit lib pkgs; };
  inherit (grafana)
    mkDashboardsProvisioning
    mkRule
    mkStat
    ;

  coreutils = "${pkgs.coreutils}/bin";

  # ---------------------------------------------------------------- status UI
  # Published to node_exporter's textfile collector (see the exporter options
  # below) and rendered by the provisioned Grafana dashboard.
  metricsDir = "/var/lib/node-exporter-textfile";


  # Age of the newest data is what matters, so the interesting signals are
  # "how old is the last snapshot" and "did the last run fail", not wall-clock
  # timestamps.
  mkAgeThresholds = [
    {
      color = "green";
      value = null;
    }
    {
      color = "yellow";
      value = 30 * 3600;
    }
    {
      color = "red";
      value = 60 * 3600;
    }
  ];

  dashboard = {
    uid = "restic-backups";
    title = "Backups (restic)";
    tags = [
      "backup"
      "restic"
    ];
    timezone = "browser";
    schemaVersion = 39;
    version = 1;
    refresh = "5m";
    time = {
      from = "now-7d";
      to = "now";
    };
    panels = [
      (mkStat {
        title = "Age of last snapshot";
        expr = "time() - max(restic_last_snapshot_timestamp_seconds)";
        x = 0;
        y = 0;
        unit = "s";
        thresholds = mkAgeThresholds;
        noValue = "no snapshot yet";
      })
      (mkStat {
        title = "Last backup run";
        expr = "max(restic_backup_last_run_success)";
        x = 6;
        y = 0;
        mappings = [
          {
            type = "value";
            options = {
              "0" = {
                text = "failed";
                color = "red";
                index = 0;
              };
              "1" = {
                text = "ok";
                color = "green";
                index = 1;
              };
            };
          }
        ];
        noValue = "never ran";
      })
      (mkStat {
        title = "Snapshots in repo";
        expr = "max(restic_snapshots_total)";
        x = 12;
        y = 0;
      })
      (mkStat {
        title = "Repository size";
        expr = "max(restic_repo_size_bytes)";
        x = 18;
        y = 0;
        unit = "bytes";
      })
      (mkStat {
        title = "Age of postgres dumps";
        expr = "time() - max(restic_postgres_dump_timestamp_seconds)";
        x = 0;
        y = 4;
        unit = "s";
        thresholds = mkAgeThresholds;
        noValue = "no dump yet";
      })
      (mkStat {
        title = "Last run exit code";
        expr = "max(restic_backup_last_run_exit_code)";
        x = 6;
        y = 4;
        thresholds = [
          {
            color = "green";
            value = null;
          }
          {
            color = "red";
            value = 1;
          }
        ];
      })
      {
        type = "timeseries";
        title = "Bytes added per snapshot";
        gridPos = {
          h = 8;
          w = 24;
          x = 0;
          y = 8;
        };
        targets = [
          {
            refId = "A";
            expr = "max(restic_last_snapshot_data_added_bytes)";
            legendFormat = "data added";
          }
        ];
        fieldConfig.defaults = {
          unit = "bytes";
          custom = {
            fillOpacity = 10;
            lineWidth = 1;
            showPoints = "never";
          };
        };
      }
      {
        type = "timeseries";
        title = "restic unit failed";
        gridPos = {
          h = 6;
          w = 24;
          x = 0;
          y = 16;
        };
        targets = [
          {
            refId = "A";
            expr = "max(node_systemd_unit_state{name=\"restic-backups-homelab.service\",state=\"failed\"})";
            legendFormat = "failed";
          }
        ];
        fieldConfig.defaults = {
          max = 1;
          min = 0;
          custom = {
            fillOpacity = 10;
            lineWidth = 1;
            showPoints = "never";
          };
        };
      }
    ];
  };

  # Backup-specific alerts; the homelab-wide ones live in ../../metrics/alerts.nix.
  alertRules = [
    (mkRule {
      uid = "restic-snapshot-stale";
      title = "Restic snapshot is stale";
      expr = "time() - max(restic_last_snapshot_timestamp_seconds)";
      op = "gt";
      threshold = 30 * 3600;
      summary = "The newest restic snapshot is older than 30h — check restic-backups-homelab.";
    })
    (mkRule {
      uid = "postgres-dump-stale";
      title = "Postgres dumps are stale";
      expr = "time() - max(restic_postgres_dump_timestamp_seconds)";
      op = "gt";
      threshold = 30 * 3600;
      summary = "services.postgresqlBackup has not produced a dump in 30h.";
    })
  ];
in
{
  # Hook the metrics unit onto the backup job, whatever the outcome.
  systemd.services.restic-backups-homelab.unitConfig = {
    OnSuccess = [ "restic-backup-metrics.service" ];
    OnFailure = [ "restic-backup-metrics.service" ];
  };

  services.prometheus.exporters.node = {
    enabledCollectors = [ "textfile" ];
    extraFlags = [ "--collector.textfile.directory=${metricsDir}" ];
  };

  services.grafana.provision.dashboards.settings = mkDashboardsProvisioning "backups" {
    backups = dashboard;
  };

  systemd.tmpfiles.rules = [
    "d ${metricsDir} 0755 root root - -"
  ];

  # Backup alerts only; the homelab-wide rule group is provisioned separately.
  services.grafana.provision.alerting.rules.settings = {
    apiVersion = 1;
    groups = [
      {
        orgId = 1;
        name = "backups";
        # Grafana's file provisioning creates the folder if it is missing.
        folder = "Homelab";
        interval = "1m";
        rules = alertRules;
      }
    ];
  };

  # Collects what systemd cannot tell us (repo contents) straight from the repo,
  # and what systemd knows (result/exit code) from the unit, then writes a
  # single .prom file for node_exporter.
  systemd.services.restic-backup-metrics = {
    description = "Publish restic backup status to node_exporter";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    startAt = "*-*-* 06:00:00"; # periodic refresh, independent of the backup run
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets.restic.path;
      # the repo lives on the NAS, don't wedge the unit if it is unreachable
      TimeoutStartSec = "5min";
    };
    script = ''
      set -uo pipefail

      unit=restic-backups-homelab.service
      out_file=${metricsDir}/restic.prom
      tmp_file=$out_file.tmp

      systemctl=${pkgs.systemd}/bin/systemctl
      date=${coreutils}/date
      jq=${lib.getExe pkgs.jq}
      restic=${lib.getExe pkgs.restic}

      success=0
      exit_code=0
      last_run_ts=0
      snapshots_total=0
      last_snapshot_ts=0
      data_added=0
      processed=0
      files_new=0
      repo_size=0
      pg_dump_ts=0

      # systemd's verdict on the last run
      result=$($systemctl show -p Result --value $unit 2>/dev/null || echo unknown)
      exit_code=$($systemctl show -p ExecMainStatus --value $unit 2>/dev/null || echo 0)
      last_run=$($systemctl show -p InactiveExitTimestamp --value $unit 2>/dev/null || echo n/a)
      if [ -n "$last_run" ] && [ "$last_run" != "n/a" ]; then
        last_run_ts=$($date -d "$last_run" +%s 2>/dev/null || echo 0)
      fi
      if [ "$result" = "success" ]; then
        success=1
      fi

      # repository truth
      snapshots_json=$($restic snapshots --json 2>/dev/null || echo '[]')
      snapshots_total=$(printf '%s' "$snapshots_json" | $jq 'length' 2>/dev/null || echo 0)
      last_time=$(printf '%s' "$snapshots_json" | $jq -r 'sort_by(.time) | last | .time // ""' 2>/dev/null || echo "")
      if [ -n "$last_time" ]; then
        last_snapshot_ts=$($date -d "$last_time" +%s 2>/dev/null || echo 0)
      fi
      data_added=$(printf '%s' "$snapshots_json" | $jq -r 'sort_by(.time) | last | .summary.data_added // 0' 2>/dev/null || echo 0)
      processed=$(printf '%s' "$snapshots_json" | $jq -r 'sort_by(.time) | last | .summary.total_bytes_processed // 0' 2>/dev/null || echo 0)
      files_new=$(printf '%s' "$snapshots_json" | $jq -r 'sort_by(.time) | last | .summary.files_new // 0' 2>/dev/null || echo 0)
      repo_size=$($restic stats --json --mode raw-data 2>/dev/null | $jq -r '.total_size // 0' 2>/dev/null || echo 0)

      # newest postgres dump, written by services.postgresqlBackup
      if [ -d /var/backup/postgresql ]; then
        pg_dump_ts=$(${pkgs.findutils}/bin/find /var/backup/postgresql -type f -name '*.sql*' -printf '%T@\n' 2>/dev/null |
          ${coreutils}/sort -n | ${coreutils}/tail -n1 | ${coreutils}/cut -d. -f1 || echo 0)
      fi

      {
        echo '# HELP restic_backup_last_run_success 1 when the last run exited cleanly.'
        echo '# TYPE restic_backup_last_run_success gauge'
        echo "restic_backup_last_run_success $success"
        echo '# TYPE restic_backup_last_run_exit_code gauge'
        echo "restic_backup_last_run_exit_code $exit_code"
        echo '# TYPE restic_backup_last_run_timestamp_seconds gauge'
        echo "restic_backup_last_run_timestamp_seconds $last_run_ts"
        echo '# TYPE restic_snapshots_total gauge'
        echo "restic_snapshots_total $snapshots_total"
        echo '# TYPE restic_last_snapshot_timestamp_seconds gauge'
        echo "restic_last_snapshot_timestamp_seconds $last_snapshot_ts"
        echo '# TYPE restic_last_snapshot_data_added_bytes gauge'
        echo "restic_last_snapshot_data_added_bytes $data_added"
        echo '# TYPE restic_last_snapshot_processed_bytes gauge'
        echo "restic_last_snapshot_processed_bytes $processed"
        echo '# TYPE restic_last_snapshot_files_new gauge'
        echo "restic_last_snapshot_files_new $files_new"
        echo '# TYPE restic_repo_size_bytes gauge'
        echo "restic_repo_size_bytes $repo_size"
        echo '# TYPE restic_postgres_dump_timestamp_seconds gauge'
        echo "restic_postgres_dump_timestamp_seconds $pg_dump_ts"
      } > "$tmp_file"

      ${coreutils}/chmod 0644 "$tmp_file"
      ${coreutils}/mv "$tmp_file" "$out_file"
    '';
  };
}
