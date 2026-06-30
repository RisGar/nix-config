{ config, ... }:
{
  apps."metrics" = {
    socket = config.services.grafana.settings.server.socket;
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        protocol = "socket";
        enable_gzip = true;
        root_url = "https://${config.apps."metrics".hostname}";
      };

      security.secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";

      # auth.disable_login_form = true;

      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        # auto_login = true; name = "Pocket ID";
        client_id = "9f9c6b4a-d46a-43ab-9a24-f376a0669a74";
        # client_secret is loaded via EnvironmentFile
        scopes = "openid profile email groups";
        auth_url = "${config.services.pocket-id.settings.APP_URL}/authorize";
        token_url = "${config.services.pocket-id.settings.APP_URL}/api/oidc/token";
        api_url = "${config.services.pocket-id.settings.APP_URL}/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        role_attribute_path = "contains(groups, 'admin') && 'Admin' || 'Viewer'";
      };

      "auth.anonymous".enabled = true;

      analytics.reporting_enabled = false;
    };
    # declarativePlugins = with pkgs.grafanaPlugins; [ ];

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          # stable uid so provisioned alert rules can reference it
          uid = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          isDefault = true;
          editable = false;
        }
      ];
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = [ config.sops.secrets."grafana/env".path ];
}
