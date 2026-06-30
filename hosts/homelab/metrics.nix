{ config, ... }:
{

  apps."metrics" = {
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        protocol = "socket";
        # http_addr = "127.0.0.1";
        # http_port = config.apps."metrics".port;
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
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          isDefault = true;
          editable = false;
        }
      ];
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = [ config.sops.secrets."grafana/env".path ];

  services.prometheus = {
    enable = true;
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
        ];
        port = 9002;
      };
    };

    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
      {
        job_name = "yopass";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.virtualisation.oci-containers.containers.yopass.environment.METRICS_PORT}"
            ];
          }
        ];
      }
    ];
  };

}
