{
  config,
  lib,
  pkgs,
  ...
}:
let
  seshExe = lib.getExe config.programs.sesh.package;
in
{
  programs.tmux = {
    enable = true;
    mouse = false;
    prefix = "C-a";
    extraConfig = ''
      set -g default-terminal "screen-256color"
      set -a terminal-features "tmux-256color:RGB:cnorm=\E[?12h\E[?25h"

      set -g base-index 1
      set -g renumber-windows on   
      set -g mode-keys vi

      set -g status-position top
      set -g status-justify absolute-centre
      set -g status-style "bg=default"
      set -g window-status-style "bg=default"
      set -g window-status-current-style "fg=blue bold bg=default"
      set -g status-left ""
      set -g status-right "#S"

      set -g history-limit 50000
      set -g focus-events on
      set -g detach-on-destroy off  # don't exit from tmux when closing a session

      # Image passthrough
      set -gq allow-passthrough all
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      set -g clock-mode-style 24

      # Set new panes to open in current directory
      bind c new-window -c "#{pane_current_path}"
      bind - split-window -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"

      bind r source-file "~/.config/tmux/tmux.conf"
      bind b set -g status
      bind ü copy-mode
      bind x kill-pane # skip "kill-pane? (y/n)" prompt

      bind-key a display-popup -b rounded -E -xC -yC -w 80% -h 70% "${lib.getExe config.programs.television.package} sesh"

      bind-key g display-popup -b rounded -E -xC -yC -w 80% -h 80% -d "#{pane_current_path}" ${lib.getExe config.programs.lazygit.package} 

      bind-key N display-popup -b rounded -E -w 80% -h 80% "${config.home.sessionVariables.EDITOR} ~/Documents/Notes/scratch.md"

      # vim like selection keys
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    '';
  };

  programs.sesh = {
    enable = true;
    enableTmuxIntegration = false; # TODO: custom prompt with nerd font instead of emojis via overlay
    settings = {
      default_session = {
        startup_command = "${config.home.sessionVariables.EDITOR} -c ':lua Snacks.picker.files(opts)'";
      };

      session = [
        {
          name = "Nix 󱄅 ";
          path = config.vars.systemFlake;
        }
        {
          name = "Spotify  ";
          path = config.home.homeDirectory;
          startup_command = lib.getExe pkgs.spotify-player;
        }
        {
          name = "Notes 󰎞 ";
          path = "${config.home.homeDirectory}/Documents/Notes";

        }
        {
          name = "University  ";
          path = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~md~obsidian/Documents/University";
        }
        {
          name = "Second Brain  ";
          path = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents/Second Brain";
        }
      ];
    };
  };
}
