{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Fonts
    maple-mono.NF
    jost
    raleway
    source-sans
    libertinus
    hanken-grotesk
    carlito
    cabin
    libre-bodoni
    libre-franklin
    inter
    overpass
  ];

  fonts.fontconfig.enable = true;
}
