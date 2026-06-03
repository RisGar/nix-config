{
  config,
  lib,
  ocrtool-mcp,
  pkgs,
  ...
}:
let
  # Map programs.mcp.servers into Antigravity's mcp_config.json format.
  # The HM module uses `url` for HTTP transport; Antigravity expects `serverUrl`.
  toAntigravityServer =
    _name: server:
    lib.filterAttrs (_: v: v != null) {
      serverUrl = server.url or null;
      command = server.command or null;
      args = server.args or null;
      env = server.env or null;
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

  home.file.".gemini/config/GEMINI.md".source = ./AGENTS.md;
  home.file.".gemini/config/skills/find-docs".source = ./skills/find-docs;
  home.file.".gemini/config/skills/nix-search".source = ./skills/nix-search;
  home.file.".gemini/config/mcp_config.json".text = builtins.toJSON {
    mcpServers = lib.mapAttrs toAntigravityServer config.programs.mcp.servers;
  };

  # programs.gemini-cli = {
  #   enable = true;
  #   enableMcpIntegration = true;
  #   context = {
  #     AGENTS = lib.readFile ./AGENTS.md;
  #   };
  #   skills = {
  #     find-docs = ./skills/find-docs;
  #     nix-search = ./skills/nix-search;
  #   };
  #   settings = {
  #     context = {
  #       loadMemoryFromIncludeDirectories = true;
  #       fileName = [
  #         "AGENTS.md"
  #         "GEMINI.md"
  #       ];
  #     };
  #     general = {
  #       preferredEditor = lib.getExe pkgs.nvim;
  #       vimMode = true;
  #     };
  #     privacy = {
  #       usageStatisticsEnabled = false;
  #     };
  #     security = {
  #       auth = {
  #         selectedType = "oauth-personal";
  #       };
  #     };
  #     ui = {
  #       theme = "Atom One";
  #       inlineThinkingMode = "full";
  #       showCitations = true;
  #       showModelInfoInChat = true;
  #       loadingPhrases = "tips";
  #     };
  #     experimental = {
  #       worktrees = true;
  #     };
  #   };
  # };

  services.ollama = {
    enable = true;
  };

}
