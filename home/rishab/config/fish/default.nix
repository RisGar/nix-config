{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  autoStartTmux = true;
  autoStartFastfetch = false;
in
{

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
    };
  };
  home.preferXdgDirectories = true;

  home.shellAliases = {
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";

    cd = "z";
    ".." = "z ..";

    nixrepl = "${lib.getExe config.nix.package} repl --expr '{inherit (import <nixpkgs> {}) pkgs lib;}'";
    nixtree = "${lib.getExe pkgs.nix-tree} --derivation \"${config.vars.systemFlake}#darwinConfigurations.Rishabs-MacBook-Pro.config.system.build.toplevel\"";

    spotify-dlp = "${lib.getExe pkgs.yt-dlp} -f \"ba[ext=m4a]\" -x --audio-format m4a --embed-thumbnail --embed-metadata --sponsorblock-remove music_offtopic -o \"~/Music/Spotify/%(artist,uploader)s - %(title)s.%(ext)s\"";

    homelab-reload = "${lib.getExe pkgs.nixos-rebuild} switch --flake ${config.vars.systemFlake}#Rishabs-Homelab --target-host 192.168.178.42 --build-host 192.168.178.42 --sudo --no-reexec --use-substitutes";
    psa-reload = "NIX_SSHOPTS='-p 60204' ${lib.getExe pkgs.nixos-rebuild} switch --flake ${config.xdg.userDirs.projects}/psa#vmpsateam02-04 --target-host root@psa.in.tum.de --build-host root@psa.in.tum.de --sudo --no-reexec --use-substitutes";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/go/bin"
    config.xdg.binHome
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    "/Library/TeX/texbin"
  ];

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "$TMPDIR";

    LANG = "en_GB.UTF-8";

    LS_COLORS = "1"; # TODO

    # Use neovim as default editor and manpager
    EDITOR = lib.getExe pkgs.nvim;
    VISUAL = lib.getExe pkgs.nvim;
    MANPAGER = (lib.getExe pkgs.nvim) + " +Man!";

    PAGER = lib.getExe pkgs.less;

    # MACOSX_DEPLOYMENT_TARGET = 15;

    HOMEBREW_BAT = 1;

    # Force programs to use XDG dirs
    OPAMROOT = "${config.xdg.dataHome}/opam";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
    GHCUP_USE_XDG_DIRS = 1;
    STACK_XDG = 1;
    KAGGLE_CONFIG_DIR = "${config.xdg.configHome}/kaggle";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
    UNISON = "${config.xdg.dataHome}/unison";
    JULIA_DEPOT_PATH = "${config.xdg.dataHome}/julia:$JULIA_DEPOT_PATH";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";
    NPM_CONFIG_INIT_MODULE = "${config.xdg.configHome}/npm/config/npm-init.js";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_TMP = "${config.home.sessionVariables.XDG_RUNTIME_DIR}/npm";

    ## C(++) compilers
    CC = lib.getExe' pkgs.llvmPackages_latest.clang "clang";
    CXX = lib.getExe' pkgs.llvmPackages_latest.clang "clang++";

    WAYLAND_DISPLAY = "wayland-0";
  };

  programs.fish = {
    enable = true;

    generateCompletions = true;

    shellInit = ''
      set -gx CONTEXT7_API_KEY (string trim < ${config.age.secrets.context7.path})
      set -gx OPENROUTER_API_KEY (string trim < ${config.age.secrets.openrouter.path})

      set fish_cursor_default block blink
      set fish_cursor_insert line blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_replace underscore blink
      set fish_cursor_external line blink

      # bind -M visual -m default y "fish_clipboard_copy; commandline -f end-selection repaint-mode"
      # bind p forward-char "commandline -i ( pbpaste; echo )[1]" # TODO
    '';

    # Autostart tmux if enabled
    shellInitLast = lib.optionalString autoStartTmux ''
      if status is-interactive
      and not set -q TMUX
        exec ${lib.getExe config.programs.tmux.package} new -As0
      end
    '';

    functions = {
      # Adapted from https://gist.github.com/jsongerber/7dfd9f2d22ae060b98e15c5590c4828d
      oil = {
        description = "opens pre-configured ssh hosts with oil";
        body = ''
          set host (${lib.getExe pkgs.gnugrep} 'Host\>' ~/.ssh/config | ${lib.getExe pkgs.gnused} 's/^Host //' | ${lib.getExe pkgs.gnugrep} -v '\*' | ${lib.getExe pkgs.gum} filter --limit 1 --no-sort --fuzzy --placeholder 'Pick an ssh host' --prompt="󰣀 ")
          if test -z "$host"
              return 0
          end
          set user (ssh -G "$host" | ${lib.getExe pkgs.gnugrep} '^user\>' | ${lib.getExe pkgs.gnused} 's/^user //')
          ${config.home.sessionVariables.EDITOR} oil-ssh://$user@$host/
        '';
      };

      reload = {
        description = "reloads nix-darwin";
        body = ''
          sudo -i ${lib.getExe osConfig.system.build.darwin-rebuild} switch -I ${config.vars.systemFlake}#${config.vars.hostname} $argv
          ghostty +validate-config
          ${lib.getExe config.programs.tmux.package} source-file ~/.config/tmux/tmux.conf
          source ~/.config/fish/config.fish
        '';
      };

      clear = {
        wraps = "clear";
        body = ''
          command clear
          if set TMUX
            ${lib.getExe config.programs.tmux.package} clear-history
          end
        '';
      };

      fix-atuin = {
        description = "fixes atuin by killing hanging processes and restarting the daemon";
        body = ''
          echo "Killing hanging atuin processes..."
          pkill -9 atuin 2>/dev/null
          echo "Restarting atuin daemon..."
          launchctl stop org.nix-community.home.atuin-daemon 2>/dev/null
          launchctl start org.nix-community.home.atuin-daemon
          sleep 1
          atuin daemon status
        '';
      };

      # Fastfetch on greeting
      fish_greeting = {
        body = if autoStartFastfetch then lib.getExe config.programs.fastfetch.package else "";
      };

      # Starship transient prompts
      starship_transient_prompt_func = {
        body =
          if config.programs.starship.enable then
            "${lib.getExe config.programs.starship.package} module character"
          else
            "";

      };
      starship_transient_rprompt_func = {
        body =
          if config.programs.starship.enable then
            "${lib.getExe config.programs.starship.package} module time"
          else
            "";
      };

      # Vi mode
      fish_user_key_bindings = {
        body = ''
          fish_default_key_bindings -M insert
          fish_vi_key_bindings --no-erase insert
        '';
      };
    };
    shellAbbrs = {
      gc = "sesh clone";
    };
    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair-fish.src;
      }
      {
        name = "puffer-fish"; # Expand consecutive dots
        src = pkgs.fishPlugins.puffer.src;
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "v0.7.0";
          hash = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
    ];
  };

  programs.atuin = {
    enable = true;
    forceOverwriteSettings = true;
    daemon.enable = true;
  };
}
