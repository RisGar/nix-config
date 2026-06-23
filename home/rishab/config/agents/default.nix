{
  config,
  lib,
  ocrtool-mcp,
  pkgs,
  ...
}:
let
  drawio-skill = pkgs.fetchFromGitHub {
    owner = "Agents365-ai";
    repo = "drawio-skill";
    rev = "ccded6f65a58e23749ca0695a0fd05552323b5cd";
    hash = "sha256-tH64pcaIJgMkVU7wxCnvCxhLYBwfuC3CBf/n6ev14vw=";
  };
  nix-search-src = pkgs.fetchFromGitHub {
    owner = "0xferrous";
    repo = "agent-stuff";
    rev = "6f4c819eaaad22c9dd86b5e0cf920952e39de6a1";
    hash = "sha256-OeVS9NSTZbMDUObfnaTaJioQtnE2nbdhwD2IwLnBSJo=";
  };
in

{
  programs.mcp = {
    enable = true;
    servers = {
      ocrtool = {
        command = lib.getExe ocrtool-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      things = {
        command = lib.getExe' config.programs.uv.package "uvx";
        args = [ "things-mcp" ];
      };
      nixos = {
        command = lib.getExe' config.programs.uv.package "uvx";
        args = [ "mcp-nixos" ];
      };
    };
  };

  # xdg.configFile."opencode/AGENTS.md".source = ./AGENTS.md;
  # programs.opencode = {
  #   enable = true;
  #   enableMcpIntegration = true;
  #   settings = builtins.fromJSON (builtins.readFile ./opencode.json);
  # };

  programs.antigravity-cli = {
    enable = true;
    enableMcpIntegration = true;
    context = {
      GEMINI = lib.readFile ./AGENTS.md;
    };
    skills = {
      find-docs = ./skills/find-docs;
      nix-search = "${nix-search-src}/skills/nix-search";
      drawio-skill = "${drawio-skill}/skills/drawio-skill";
    };
    settings = {
      enableTelemetry = false;
      # enableTerminalSandbox = true;
      notifications = true;
      toolPermission = "proceed-in-sandbox";
    };
  };

  services.ollama = {
    enable = true;
  };

}
