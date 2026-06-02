{ config, lib, ... }:
let
  fd = lib.getExe config.programs.fd.package;
  sesh = lib.getExe config.programs.sesh.package;
  tmux = lib.getExe config.programs.tmux.package;
in
{
  programs.fzf = {
    enable = true;

    defaultOptions = [
      "--cycle"
      "--layout=reverse"
      "--border=rounded"
      "--preview-window=border-rounded"
      "--prompt='󰘧  '"
      "--info=right"
    ];

    colors = with config.lib.stylix.colors.withHashtag; {
      "bg+" = base01;
      spinner = base0C;
      hl = base0D;
      header = base0D;
      info = base0A;
      pointer = base0C;
      marker = base0C;
      prompt = base0A;
      "hl+" = base0D;
    };

    # Don't use tmux/shell integration as `fzf-tmux` has been replaced by `--tmux`
  };

  programs.television = {
    enable = true;
    channels = {
      sesh = {
        metadata = {
          name = "sesh";
          description = "Session manager integrating tmux sessions, zoxide directories, and config paths";
          requirements = [
            "sesh"
            "fd"
          ];
        };
        source = {
          ansi = true;
          frecency = false;
          no_sort = true;
          output = "{strip_ansi|split: :1..|join: }";
          command = [
            {
              name = "All";
              run = "${sesh} list --icons";
            }
            {
              name = "Tmux";
              run = "${sesh} list -t --icons";
            }
            {
              name = "Projects";
              run = "${fd} -H -d 1 -t d -E .Trash . ${config.xdg.userDirs.projects} -x basename";
            }
          ];
        };
        preview = {
          command = "set res '{strip_ansi|split: :1..|join: }'; if test -d \"${config.xdg.userDirs.projects}/$res\"; ${sesh} preview \"${config.xdg.userDirs.projects}/$res\"; else; ${sesh} preview \"$res\"; end";
        };
        keybindings = {
          enter = "actions:connect";
          "ctrl-d" = [
            "actions:kill_session"
            "reload_source"
          ];
        };
        actions = {
          connect = {
            description = "Connect to selected session";
            command = "set res '{strip_ansi|split: :1..|join: }'; if test -d \"${config.xdg.userDirs.projects}/$res\"; ${sesh} connect \"${config.xdg.userDirs.projects}/$res\"; else; ${sesh} connect \"$res\"; end";
            mode = "execute";
          };
          kill_session = {
            description = "Kill selected tmux session (press Ctrl+r to reload)";
            command = "${tmux} kill-session -t '{strip_ansi|split: :1..|join: }'";
            mode = "fork";
          };
        };
      };
    };
  };

  programs.nix-search-tv = {
    enable = true;
    settings = {
      indexes = [
        "nixpkgs"
        "home-manager"
        "darwin"
        "nur"
        "noogle"
        "stylix"
      ];

      experimental = {
        render_docs_indexes = {
          nix-darwin = "https://nix-darwin.github.io/nix-darwin/manual/index.html";
          stylix = "https://nix-community.github.io/stylix/print.html";
        };
      };
    };
  };
}
