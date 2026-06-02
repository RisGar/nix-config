{
  config,
  lib,
  ocrtool-mcp,
  pkgs,
  ...
}:
{
  programs.mcp = {
    enable = true;
    servers = {
      tavily = {
        url = "https://mcp.tavily.com/mcp/?tavilyApiKey={env:TAVILY_API_KEY}";
      };
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
  # home.file.".agents/skills/find-docs/SKILL.md".source = ./skills/find-docs/SKILL.md;
  # programs.opencode = {
  #   enable = true;
  #   enableMcpIntegration = true;
  #   settings = builtins.fromJSON (builtins.readFile ./opencode.json);
  # };

  programs.gemini-cli = {
    enable = true;
    enableMcpIntegration = true;
    context = {
      AGENTS = lib.readFile ./AGENTS.md;
    };
    skills = {
      find-docs = ./skills/find-docs;
    };
    settings = {
      context = {
        loadMemoryFromIncludeDirectories = true;
        fileName = [
          "AGENTS.md"
          "GEMINI.md"
        ];
      };
      general = {
        preferredEditor = lib.getExe pkgs.nvim;
        vimMode = true;
      };
      privacy = {
        usageStatisticsEnabled = false;
      };
      security = {
        auth = {
          selectedType = "oauth-personal";
        };
      };
      ui = {
        theme = "Atom One";
        inlineThinkingMode = "full";
        showCitations = true;
        showModelInfoInChat = true;
        loadingPhrases = "tips";
      };
      experimental = {
        worktrees = true;
      };
    };
  };

  services.ollama = {
    enable = true;
  };

}
