{ lib, pkgs, ... }:
let
  grafana = import ../../../../lib/grafana.nix { inherit lib pkgs; };
  inherit (grafana) mkDashboardsProvisioning;

  # One file per dashboard; each takes just the panel builders it needs.
  dashboards = {
    tunnel-web = import ./tunnel-web.nix grafana;
    resources = import ./resources.nix grafana;
    databases = import ./databases.nix grafana;
  };
in
{
  services.grafana.provision.dashboards.settings = mkDashboardsProvisioning {
    name = "homelab";
    inherit dashboards;
    # same folder the alert rules are provisioned into, so it is not empty
    folder = "Homelab";
  };
}
