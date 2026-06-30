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
      uid = "tls-expiring";
      title = "TLS certificate expires soon";
      expr = "min(probe_ssl_earliest_cert_expiry) - time()";
      op = "lt";
      threshold = 14 * 86400;
      for = "1h";
      summary = "A probed site has a certificate expiring in under 14 days.";
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
      title = "SMART health check failed";
      expr = "min(smartctl_device_smart_status)";
      op = "lt";
      threshold = 1;
      for = "5m";
      severity = "critical";
      summary = "A disk reports a failed SMART self-assessment.";
    })
  ];
in
{
  # No contact point on purpose: the notification channel needs a credential
  # (ntfy topic / telegram bot token), see TODO.md. Until one is added the rules
  # still show as pending/firing in the Grafana UI.
  services.grafana.provision.alerting.rules.settings = {
    apiVersion = 1;
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
