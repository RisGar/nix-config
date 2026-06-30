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
      qt.enable = false; # Doesn't work on macOS
      # TODO: obsidian, opencode, neovim
    };
  };

  stylix.targets.zen-browser.profileNames = [ "default" ];

}
