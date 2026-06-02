{
  pkgs,
  lib,
  config,
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
      projects = "${config.xdg.userDirs.documents}/Programming";
    };
  };
  home.preferXdgDirectories = true;

  home.shellAliases = {
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";

    cd = "z";
    ".." = "z ..";

    nixrepl = "nix repl --expr '{inherit (import <nixpkgs> {}) pkgs lib;}'";
    nixtree = "nix-tree --derivation \"${config.vars.systemFlake}#darwinConfigurations.Rishabs-MacBook-Pro.config.system.build.toplevel\"";

    spotify-dlp = "yt-dlp -f \"ba[ext=m4a]\" -x --audio-format m4a --embed-thumbnail --embed-metadata --sponsorblock-remove music_offtopic -o \"~/Music/Spotify/%(artist,uploader)s - %(title)s.%(ext)s\"";

    reload-homelab = "${lib.getExe pkgs.nixos-rebuild} switch --flake ${config.vars.systemFlake}#Rishabs-Homelab --target-host homelab --sudo";
    reload-homelab-local = "${lib.getExe pkgs.nixos-rebuild} switch --flake ${config.vars.systemFlake}#Rishabs-Homelab --target-host 192.168.178.42 --sudo";
  };

  home.sessionPath = [
    config.programs.go.env.GOBIN
    config.home.sessionVariables.XDG_BIN_HOME
    "${config.home.sessionVariables.CARGO_HOME}/bin"
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

    # Homebrew config
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "${config.home.sessionVariables.HOMEBREW_PREFIX}/Cellar";
    HOMEBREW_REPOSITORY = "${config.home.sessionVariables.HOMEBREW_PREFIX}";
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
    # DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    # COLIMA_HOME = "${config.xdg.configHome}/colima";
    # DOCKER_HOST = "unix://${config.home.sessionVariables.COLIMA_HOME}/default/docker.sock";

    ## C(++) compilers
    CC = lib.getExe pkgs.llvmPackages_latest.clang;
    CXX = lib.getExe pkgs.llvmPackages_latest.clang + "++";

    WAYLAND_DISPLAY = "wayland-0";
  };

  home.sessionSearchVariables = {
    MANPATH = [
      "${config.home.sessionVariables.HOMEBREW_PREFIX}/share/man"
      "${config.home.sessionVariables.HOMEBREW_PREFIX}/opt/libarchive/share/man"
    ];
    INFOPATH = [ "${config.home.sessionVariables.HOMEBREW_PREFIX}/share/info" ];
    fish_complete_path = [
      "${config.home.sessionVariables.HOMEBREW_PREFIX}/share/fish/vendor_completions.d"
      "${config.home.sessionVariables.HOMEBREW_PREFIX}/share/fish/completions"
    ];
    __fish_vendor_confdirs = [
      "${config.home.sessionVariables.HOMEBREW_PREFIX}/share/fish/vendor_conf.d"
    ];

  };

  programs.fish = {
    enable = true;

    generateCompletions = true;

    shellInit = ''
      set -gx CONTEXT7_API_KEY (string trim < ${config.age.secrets.context7.path})
      set -gx TAVILY_API_KEY (string trim < ${config.age.secrets.tavily.path})
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
        exec tmux new -As0
      end
    '';

    functions = {
      # Adapted from https://gist.github.com/jsongerber/7dfd9f2d22ae060b98e15c5590c4828d
      oil = {
        description = "Opens pre-configured ssh hosts with oil";
        body = ''
          set host (grep 'Host\>' ~/.ssh/config | sed 's/^Host //' | grep -v '\*' | ${lib.getExe pkgs.gum} filter --limit 1 --no-sort --fuzzy --placeholder 'Pick an ssh host' --prompt="󰣀 ")
          if test -z "$host"
              return 0
          end
          set user (ssh -G "$host" | grep '^user\>' | sed 's/^user //')
          ${config.home.sessionVariables.EDITOR} oil-ssh://$user@$host/
        '';
      };

      reload = {
        description = "Reloads nix-darwin";
        body = ''
          sudo -i darwin-rebuild switch -I ${config.vars.systemFlake}#${config.vars.hostname} $argv
          ghostty +validate-config
          tmux source-file ~/.config/tmux/tmux.conf
          source ~/.config/fish/config.fish
        '';
      };

      clear = {
        wraps = "clear";
        body = ''
          command clear
          if set TMUX
            tmux clear-history
          end
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
}
