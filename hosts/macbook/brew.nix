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
    ];

    casks = [
      # "bookends"
      "endnote"
      "gog-galaxy"
      "grammarly-desktop"
      "middle"
      "moneymoney"
      "nextcloud"
      "pdf-pals"
      "steermouse"
      "timemator"
      "tower"
      "ukelele"

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
      "pearcleaner"
      "prusaslicer"
      "qlmarkdown"
      "quicklook-video"
      "spotify" # breaks often on nix
      "steam"
      "telegram" # nixpkgs only has telegram-desktop, not telegram-swift
      "transmission-remote-gui"
      "xquartz" # TODO: make ssh -X via nix work
      "yubico-authenticator"
      "zen"
      "zulip"
      "keka"
      "handbrake-app"
      "nheko" # On nix the app is German???? and the buttons look wrong
      "ferdium"
      # Don't install Microsoft Office through brew as it would also rely on Microsoft AutoUpdate
    ];
  };
}
