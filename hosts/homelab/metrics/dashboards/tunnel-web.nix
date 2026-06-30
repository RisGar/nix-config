{
  mkStat,
  mkTimeseries,
  ...
}:
{
  uid = "homelab-tunnel-web";
  title = "Tunnel & web";
  schemaVersion = 39;
  version = 1;
  refresh = "1m";
  time = {
    from = "now-6h";
    to = "now";
  };
  panels = [
    (mkStat {
      title = "Tunnel connections";
      expr = "max(cloudflared_tunnel_ha_connections)";
      x = 0;
      y = 0;
      thresholds = [
        {
          color = "red";
          value = null;
        }
        {
          color = "green";
          value = 1;
        }
      ];
      noValue = "tunnel down";
    })
    (mkStat {
      title = "Tunnel request errors (1h)";
      expr = "sum(increase(cloudflared_tunnel_request_errors[1h]))";
      x = 6;
      y = 0;
      thresholds = [
        {
          color = "green";
          value = null;
        }
        {
          color = "yellow";
          value = 1;
        }
        {
          color = "red";
          value = 25;
        }
      ];
    })
    (mkStat {
      title = "Caddy config reload";
      expr = "max(caddy_config_last_reload_successful)";
      x = 12;
      y = 0;
      thresholds = [
        {
          color = "red";
          value = null;
        }
        {
          color = "green";
          value = 1;
        }
      ];
    })
    (mkStat {
      title = "Targets down";
      expr = "sum(up == 0)";
      x = 18;
      y = 0;
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
    (mkStat {
      title = "5xx responses/s";
      expr = "sum(rate(caddy_http_request_duration_seconds_count{code=~\"5..\"}[5m]))";
      x = 0;
      y = 4;
      unit = "reqps";
      thresholds = [
        {
          color = "green";
          value = null;
        }
        {
          color = "yellow";
          value = 0.01;
        }
        {
          color = "red";
          value = 0.1;
        }
      ];
      noValue = "no traffic";
    })
    (mkStat {
      title = "Requests in flight";
      expr = "max(caddy_http_requests_in_flight)";
      x = 6;
      y = 4;
      thresholds = [
        {
          color = "green";
          value = null;
        }
        {
          color = "yellow";
          value = 50;
        }
        {
          color = "red";
          value = 200;
        }
      ];
    })
    (mkStat {
      title = "Caddy requests/s";
      expr = "sum(rate(caddy_http_requests_total[5m]))";
      x = 12;
      y = 4;
      unit = "reqps";
    })
    (mkTimeseries {
      title = "Tunnel responses by status code";
      y = 8;
      unit = "reqps";
      targets = [
        {
          expr = "sum by (code) (rate(cloudflared_tunnel_response_by_code[5m]))";
          legend = "{{code}}";
        }
      ];
    })
    (mkTimeseries {
      title = "Caddy latency (p95 / p99) and errors";
      y = 15;
      h = 8;
      targets = [
        {
          expr = "histogram_quantile(0.95, sum by (le) (rate(caddy_http_request_duration_seconds_bucket[5m])))";
          legend = "p95";
        }
        {
          expr = "histogram_quantile(0.99, sum by (le) (rate(caddy_http_request_duration_seconds_bucket[5m])))";
          legend = "p99";
        }
        {
          expr = "sum(rate(caddy_http_request_errors_total[5m]))";
          legend = "errors/s";
        }
      ];
    })
    (mkTimeseries {
      title = "Caddy responses by status code";
      y = 23;
      h = 8;
      unit = "reqps";
      targets = [
        {
          expr = "sum by (code) (rate(caddy_http_request_duration_seconds_count[5m]))";
          legend = "{{code}}";
        }
      ];
    })
  ];
}
