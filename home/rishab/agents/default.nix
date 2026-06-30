{
  config,
  lib,
  pkgs,
  ...
}:
let
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
      things = {
        command = lib.getExe' config.programs.uv.package "uvx";
        args = [ "things-mcp" ];
      };
      strongbox = {
        command = "/Applications/Strongbox.app/Contents/MacOS/strongbox-mcp";
      };
      # logseq = {
      #   url = "https://logseq.localhost";
      #   headers = {
      #     Authorization = "Bearer YOUR_LOGSEQ_API_TOKEN";
      #   };
      # };
    };
  };

  xdg.configFile."opencode/AGENTS.md".source = ./AGENTS.md;

  # the morpheus API key must not end up in the world-readable store, so sops
  # renders it to 0400 file at activation and opencode pulls it in at runtime
  # through its {file:…} substitution. `content` is the bare placeholder on
  # purpose: a heredoc would append a newline and corrupt the key.
  sops.templates."morpheus-key".content = config.sops.placeholder.morpheus;

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./opencode.json)) {
      provider.morpheus.options.apiKey = "{file:${config.sops.templates."morpheus-key".path}}";
    };
    skills = {
      nix-search = "${nix-search-src}/skills/nix-search/SKILL.md";
    };
  };

  services.ollama = {
    enable = true;
  };

  # programs.claude-code = {
  #   enable = true;
  #   configDir = "${config.xdg.configHome}/claude";
  #   enableMcpIntegration = true;
  #   package = pkgs.symlinkJoin {
  #     name = "claude-code-deepseek";
  #
  #     inherit (pkgs.claude-code) meta version;
  #
  #     paths = [ pkgs.claude-code ];
  #     buildInputs = [ pkgs.makeWrapper ];
  #     postBuild = ''
  #       wrapProgram $out/bin/claude \
  #         --set ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic" \
  #         --run 'export ANTHROPIC_AUTH_TOKEN=$(cat ${config.sops.secrets.deepseek.path})' \
  #         --set ANTHROPIC_MODEL "deepseek-v4-pro[1m]" \
  #         --set ANTHROPIC_DEFAULT_OPUS_MODEL "deepseek-v4-pro[1m]" \
  #         --set ANTHROPIC_DEFAULT_SONNET_MODEL "deepseek-v4-pro[1m]" \
  #         --set ANTHROPIC_DEFAULT_HAIKU_MODEL "deepseek-v4-flash" \
  #         --set CLAUDE_CODE_SUBAGENT_MODEL "deepseek-v4-flash" \
  #         --set CLAUDE_CODE_EFFORT_LEVEL "max" \
  #         --set CLAUDE_CODE_AUTO_COMPACT_WINDOW "786432"
  #     '';
  #   };
  # };

  sops.templates.".reasonix-env".content = ''
    DEEPSEEK_API_KEY=${config.sops.placeholder.deepseek}
  '';
  xdg.configFile."reasonix/.env".source =
    config.lib.file.mkOutOfStoreSymlink
      config.sops.templates.".reasonix-env".path;

  home.sessionVariables = {
    REASONIX_HOME = "${config.xdg.configHome}/reasonix";
  };
}
