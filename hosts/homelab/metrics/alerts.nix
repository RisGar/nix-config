{ lib, pkgs, ... }:
let
  inherit (import ../../../lib/grafana.nix { inherit lib pkgs; }) mkRule;

  # Backup-specific rules (stale snapshots, stale postgres dumps) live next to
  # the backup job in ../../backup/metrics.nix.
  alertRules = [
    (mkRule {
      uid = "target-down";
      title = "Prometheus target down";
      expr = "min(up)";
      op = "lt";
      threshold = 1;
      for = "5m";
      severity = "critical";
      summary = "At least one scrape target is down.";
    })
    (mkRule {
      uid = "filesystem-low";
      title = "Filesystem almost full";
      expr = "min(100 * node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|ramfs|overlay\"})";
      op = "lt";
      threshold = 15;
      summary = "A filesystem has less than 15% free space.";
    })
    (mkRule {
      uid = "caddy-5xx";
      title = "Caddy is answering with 5xx";
      # Caddy's metrics carry no host label, so this is one number across every
      # vhost and cannot say *which* site is failing. A single browser tab
      # polling a Proxmox VM guest agent (~0.1 req/s of 500s) was enough to keep
      # the old 0.05 req/s threshold firing permanently, hence the higher bar and
      # the longer window: this should mean "a site is properly broken".
      expr = "sum(rate(caddy_http_request_duration_seconds_count{code=~\"5..\"}[5m]))";
      op = "gt";
      threshold = 0.5; # ~30 failed requests/minute
      for = "30m";
      summary = "Caddy is returning more than ~30 5xx responses per minute — a backend is down or unreachable.";
    })
    (mkRule {
      uid = "caddy-upstream-errors";
      title = "Caddy cannot reach a backend";
      # caddy_http_request_errors_total counts the errors Caddy itself produced
      # (mostly failed dials to the upstream), which is the actionable subset of
      # the 5xx above.
      expr = "increase(caddy_http_request_errors_total[15m])";
      op = "gt";
      threshold = 20;
      for = "15m";
      summary = "Caddy logged more than 20 upstream/handler errors in 15m — a proxied service is unreachable.";
    })
    (mkRule {
      uid = "tunnel-down";
      title = "Cloudflare tunnel has no connection";
      expr = "max(cloudflared_tunnel_ha_connections)";
      op = "lt";
      threshold = 1;
      for = "5m";
      severity = "critical";
      summary = "cloudflared reports no ready connections — nothing is reachable from outside.";
    })
    (mkRule {
      uid = "smart-failing";
      title = "smartctl cannot read a disk";
      # smart_status is not exposed on this host (virtio boot disk, USB data disk),
      # so the signal available is smartctl's own exit status per device.
      expr = "max(smartctl_device_smartctl_exit_status)";
      op = "gt";
      threshold = 0;
      for = "15m";
      severity = "critical";
      summary = "smartctl exited non-zero for a disk — the disk or its USB bridge stopped answering.";
    })
  ];
in
{
  # The rules only define what is alertable; delivery is wired separately: the
  # `ntfy` contact point and the default notification policy live in ./ntfy.nix.
  services.grafana.provision.alerting.rules.settings = {
    apiVersion = 1;
    # Grafana's file provisioning creates and updates rules but never removes
    # ones that disappear from the file, so rules retired from this list have to
    # be deleted explicitly. `tls-expiring` is the leftover from the blackbox era
    # (Cloudflare terminates TLS for every vhost here, so there was never a
    # local certificate to watch); it kept sitting in NoData in the UI.
    deleteRules = [
      {
        orgId = 1;
        uid = "tls-expiring";
      }
    ];
    groups = [
      {
        orgId = 1;
        name = "homelab";
        # Grafana's file provisioning creates the folder if it is missing.
        folder = "Homelab";
        interval = "1m";
        rules = alertRules;
      }
    ];
  };
}
