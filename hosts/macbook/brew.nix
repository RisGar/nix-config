{ config, lib, ... }:
{
  homebrew = {
    enable = true;
    enableFishIntegration = true;

    onActivation = {
      upgrade = true;
      cleanup = "uninstall";
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
      };
    };

    taps = lib.attrNames config.nix-homebrew.taps;

    brews = [
    ];

    # greedyCasks = true;
    casks = [
      "gog-galaxy"
      "moneymoney"
      "pdf-pals"
      "steermouse"
      "timemator"
      "ukelele"
      "betterdisplay"
      "affinity"
      "helium-browser"
      "nordvpn"
      "qlmarkdown"
      "quicklook-video"
      "steam"
      "telegram" # nixpkgs only has telegram-desktop, not telegram-swift
      "xquartz" # TODO: make ssh -X via nix work
      "zen"
      "zulip" # TODO: get package to work on macos
      "openvpn-connect"
      # Don't install Microsoft Office through brew as it would also rely on Microsoft AutoUpdate
    ];
  };
}
