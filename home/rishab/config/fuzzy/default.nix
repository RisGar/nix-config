{
  config,
  lib,
  pkgs,
  ...
}:
let
  projectDir = config.xdg.userDirs.projects;
  sesh = lib.getExe config.programs.sesh.package;
  tmux = lib.getExe config.programs.tmux.package;
  tldr = lib.getExe pkgs.tlrc;
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
    settings = {
      ui = {
        theme_overrides = with config.lib.stylix.colors.withHashtag; {
          border_fg = base03;
          text_fg = base05;
          dimmed_text_fg = base05;
          input_text_fg = base08;
          result_count_fg = base08;
          result_name_fg = base05;
          result_line_number_fg = base03;
          result_value_fg = base05;
          selection_bg = base01;
          selection_fg = base05;
          match_fg = base0D;
          preview_title_fg = base0A;
          channel_mode_fg = base00;
          channel_mode_bg = base0B;
        };
      };
    };
    channels = {
      sesh = {
        metadata = {
          name = "sesh";
          description = "tmux session manager";
        };
        source = {
          ansi = true;
          frecency = false;
          no_sort = true;
          output = "{strip_ansi|split: :1..|join: }";
          command = [
            {
              name = "Sesh";
              run = "${sesh} list --icons";
            }
            {
              name = "Projects";
              run = "${lib.getExe config.programs.eza.package} -D -1 ${projectDir} | ${lib.getExe pkgs.gnused} 's/^/󰉋 /'";
            }
            {
              name = "Search";
              run = "${lib.getExe config.programs.fd.package} -H -d 2 -t d -E .Trash . ~";
            }
          ];
        };
        preview = {
          command = "set res '{strip_ansi|split: :1..|join: }'; if ${tmux} has-session -t \"=$res\" 2>/dev/null; ${sesh} preview \"$res\"; else if test -d \"${projectDir}/$res\"; ${sesh} preview \"${projectDir}/$res\"; else; ${sesh} preview \"$res\"; end";
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
            command = "set res '{strip_ansi|split: :1..|join: }'; if ${tmux} has-session -t \"=$res\" 2>/dev/null; ${sesh} connect \"$res\"; else if test -d \"${projectDir}/$res\"; ${sesh} connect \"${projectDir}/$res\"; else; ${sesh} connect \"$res\"; end";
            mode = "execute";
          };
          kill_session = {
            description = "kill selected tmux session";
            command = "${tmux} kill-session -t '{strip_ansi|split: :1..|join: }'";
            mode = "fork";
          };
        };
      };
      tldr = {
        metadata = {
          name = "tldr";
          description = "browse tldr pages";
        };

        source = {
          command = "${tldr} --list";
        };

        programs = {
          command = "${tldr} '{0}' --color always";
        };

        keybindings = {
          ctrl-e = "actions:open";
        };

        actions = {
          open = {
            description = "open the selected tldr page";
            command = "${tldr} '{0}'";
            mode = "execute";
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
        "noogle"
        "nixos"
        "darwin"
        "nur"
      ];

      experimental = {
        render_docs_indexes = {
          # stylix = "https://nix-community.github.io/stylix/print.html";
        };
      };
    };
  };
}
