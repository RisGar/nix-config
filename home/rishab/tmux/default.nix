{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.tmux = {
    enable = true;
    mouse = false;
    prefix = "C-a";
    extraConfig = ''
      # Terminal features & Image passthrough
      set -g allow-passthrough all
      set -as terminal-features ",xterm-ghostty:kitty"
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",xterm-ghostty:Tc"

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


      set -g clock-mode-style 24

      # Set new panes to open in current directory
      bind c new-window -c "#{pane_current_path}"
      bind - split-window -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"

      bind r source-file "~/.config/tmux/tmux.conf"
      bind b set -g status
      bind ü copy-mode
      bind x kill-pane # skip "kill-pane? (y/n)" prompt

      bind-key a display-popup -b rounded -E -xC -yC -w 80% -h 70% "${lib.getExe config.programs.television.package} sesh --no-remote"

      bind-key g display-popup -b rounded -E -xC -yC -w 80% -h 80% -d "#{pane_current_path}" ${lib.getExe config.programs.lazygit.package} 
      bind-key j display-popup -b rounded -E -xC -yC -w 80% -h 80% -d "#{pane_current_path}" ${lib.getExe config.programs.jjui.package} 

      bind-key N display-popup -b rounded -E -w 80% -h 80% "${lib.getExe pkgs.nvim} ~/Documents/Notes/scratch.md"

      # vim like selection keys
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # vim like motions
      bind -T copy-mode-vi i switch-client -T copyModeMultiKey_i
      bind -T copyModeMultiKey_i w send-keys -X select-word
      bind -T copyModeMultiKey_i W send-keys -X clear-selection \; send-keys -X previous-space \; send-keys -X begin-selection \; send-keys -X next-space-end
      bind -T copyModeMultiKey_i b send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i ( send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i ) send-keys -X clear-selection \; send-keys -X jump-to-backward '(' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ')'
      bind -T copyModeMultiKey_i B send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i \{ send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i \} send-keys -X clear-selection \; send-keys -X jump-to-backward '{' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '}'
      bind -T copyModeMultiKey_i [ send-keys -X clear-selection \; send-keys -X jump-to-backward '[' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ']'
      bind -T copyModeMultiKey_i ] send-keys -X clear-selection \; send-keys -X jump-to-backward '[' \; send-keys -X begin-selection \; send-keys -X jump-to-forward ']'
      bind -T copyModeMultiKey_i < send-keys -X clear-selection \; send-keys -X jump-to-backward '<' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '>'
      bind -T copyModeMultiKey_i > send-keys -X clear-selection \; send-keys -X jump-to-backward '<' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '>'
      bind -T copyModeMultiKey_i ` send-keys -X clear-selection \; send-keys -X jump-to-backward '`' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '`'
      bind -T copyModeMultiKey_i \' send-keys -X clear-selection \; send-keys -X jump-to-backward "'" \; send-keys -X begin-selection \; send-keys -X jump-to-forward "'"
      bind -T copyModeMultiKey_i \" send-keys -X clear-selection \; send-keys -X jump-to-backward '"' \; send-keys -X begin-selection \; send-keys -X jump-to-forward '"'
      bind -T copyModeMultiKey_i l send-keys -X clear-selection \; send-keys -X back-to-indentation \; send-keys -X begin-selection \; send-keys -X end-of-line \; send-keys -X cursor-left \; send-keys -X other-end
    '';
  };

  programs.sesh = {
    enable = true;
    enableTmuxIntegration = false; # using pkgs.television instead
    settings = {
      default_session = {
        startup_command = lib.getExe pkgs.fastfetch;
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
          path = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents/second-brain";
        }
      ];
    };
  };

  # TODO
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
    # attachExistingSession = true;
    # exitShellOnExit = true;
  };
}
