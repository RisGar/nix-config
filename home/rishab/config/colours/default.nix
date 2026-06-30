{
  pkgs,
  config,
  lib,
  ...
}:
{
  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    polarity = "dark";
    opacity = {
      terminal = 0.0;
    };
    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = config.stylix.fonts.monospace;
    };
    targets = {
      bat.enable = true;
      btop.enable = true;
      fish.enable = false; # Manual
      fzf.enable = false; # Manual
      gtk.enable = true;
      halloy.enable = true;
      lazygit.enable = true;
      sioyek.enable = true;
      spotify-player.enable = false; # Term Colors
      starship.enable = true;
      tmux.enable = true;
      yazi.enable = true;
      zen-browser.enable = true;
      jjui.enable = false; # TODO
      # TODO: obsidian, opencode
    };
  };

  stylix.targets.zen-browser.profileNames = [ "default" ];

  xdg.configFile."fish/themes/stylix.theme".text = with config.lib.stylix.colors; ''
    # Syntax Highlighting Colors
    fish_color_normal ${base05}
    fish_color_command ${base0E}
    fish_color_quote ${base0B}
    fish_color_redirection ${base0C}
    fish_color_end ${base05}
    fish_color_error ${base08}
    fish_color_param ${base08}
    fish_color_comment ${base04}
    fish_color_match ${base0C} --underline
    fish_color_search_match --background=2e6399
    fish_color_operator ${base0E}
    fish_color_escape ${base0C}
    fish_color_cwd ${base08}
    fish_color_autosuggestion ${base05}
    fish_color_valid_path ${base08} --underline
    fish_color_history_current ${base0C}
    fish_color_selection --background=${base04}
    fish_color_user ${base0D}
    fish_color_host ${base0B}
    fish_color_cancel ${base04}

    # Completion Pager Colors
    fish_pager_color_completion ${base05}
    fish_pager_color_prefix ${base0B}
    fish_pager_color_description ${base05}
    fish_pager_color_progress ${base05}
  '';

  programs.fish.interactiveShellInit = ''
    fish_config theme choose stylix
  '';

}
