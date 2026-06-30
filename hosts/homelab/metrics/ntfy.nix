{
  config,
  lib,
  ...
}:
let
  ntfyPort = 2586;

  # The topic name is not a capability any more: auth-default-access is
  # "deny-all" and only the two ACL rows below exist. Publishing needs the
  # `grafana` account's token, reading needs an account with a grant. Accounts,
  # the bcrypt hash and the token all live in sops (see the templates below).
  topic = "homelab-alerts-0491b382";

  ntfyUrl = "https://${config.apps."alerting".hostname}";
in
{
  apps."alerting" = {
    port = ntfyPort;
  };

  sops.templates."ntfy-env" = {
    content = ''
      NTFY_AUTH_USERS=rishab:${config.sops.placeholder."ntfy/user-hash"}:user
      NTFY_AUTH_TOKENS=grafana:${config.sops.placeholder."ntfy/token"}:grafana-alerts
    '';
  };

  # Same secret, so Grafana and ntfy cannot drift apart.
  sops.templates."grafana-ntfy-env" = {
    content = ''
      NTFY_TOKEN=${config.sops.placeholder."ntfy/token"}
    '';
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile =
    config.sops.templates."grafana-ntfy-env".path;

  # Custom message template (no emoji, renders the alert annotations instead of
  # Grafana's raw label/value dump). ntfy loads it at startup from template-dir.
  environment.etc."ntfy/templates/homelab.yml".source = ./ntfy-template.yml;

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.templates."ntfy-env".path;
    settings = {
      base-url = ntfyUrl;
      template-dir = "/etc/ntfy/templates";
      listen-http = "127.0.0.1:${toString ntfyPort}";
      behind-proxy = true;
      proxy-trusted-hosts = "127.0.0.1,::1";
      upstream-base-url = "https://ntfy.sh";

      auth-default-access = "deny-all";
      auth-access = [
        "grafana:${topic}:wo" # grafana publishes alerts, but cannot read them
        "rishab:${topic}:ro" # the iOS app only subscribes
      ];

      web-root = "disable";
      enable-signup = false;
      enable-login = false;
      enable-reservations = false;

      attachment-cache-dir = lib.mkForce ""; # nothing here uses attachments

      cache-duration = "12h"; # keep messages around long enough to see what fired overnight

      # Abuse hygiene: no scheduled-message storage, a bounded topic count and
      # per-visitor limits. Loopback is exempt so Grafana is never throttled;
      # Caddy forwards the real client IP, so remote visitors still are.
      message-delay-limit = "0";
      global-topic-limit = 20;
      visitor-subscription-limit = 3;
      visitor-message-daily-limit = 500;
      visitor-request-limit-burst = 30;
      visitor-request-limit-replenish = "5s";
      visitor-request-limit-exempt-hosts = "127.0.0.1,::1";
      visitor-topic-creation-limit-burst = 10;
      visitor-topic-creation-limit-replenish = "1h";
    };
  };

  services.grafana.provision.alerting = {
    contactPoints.settings = {
      apiVersion = 1;
      contactPoints = [
        {
          orgId = 1;
          name = "ntfy";
          receivers = [
            {
              uid = "ntfy";
              type = "webhook";
              disableResolveMessage = false;
              settings = {
                url = "http://127.0.0.1:${toString ntfyPort}/${topic}?template=homelab"; # loopback rather than the public URL
                httpMethod = "POST";
                authorization_scheme = "Bearer";
                authorization_credentials = "$NTFY_TOKEN";
              };
            }
          ];
        }
      ];
    };

    policies.settings = {
      apiVersion = 1;
      policies = [
        {
          orgId = 1;
          receiver = "ntfy";
          group_by = [ "alertname" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
        }
      ];
    };
  };
}
