{ config, lib, ... }:
{
  homebrew = {
    enable = true;

    enableFishIntegration = true;
    onActivation = {
      cleanup = "uninstall";
    };

    taps = lib.attrNames config.nix-homebrew.taps;

    brews = [
      "mole"
    ];

    casks = [
      "affinity"
      "beeper"
      "boinc"
      "detexify"
      "devonthink"
      "ghostty" # not avaliable on darwin rn
      "helium-browser"
      "hyperkey"
      "macs-fan-control"
      "nordvpn"
      "onyx"
      "pearcleaner"
      "prusaslicer"
      "qlmarkdown"
      "quicklook-video"
      "spotify" # breaks often on nix
      "steam"
      "stirling-pdf" # https://github.com/NixOS/nixpkgs/pull/480680
      "telegram" # nixpkgs only has telegram-desktop, not telegram-swift
      "transmission-remote-gui"
      "tunnelblick"
      "visual-studio-code"
      "xquartz" # TODO: make ssh -X via nix work
      "yubico-authenticator"
      "zen"
      "zoom"
      "zulip"
    ];
  };
}
