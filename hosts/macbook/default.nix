{
  lib,
  pkgs,
  nixpkgs-overlay,
  self,
  ...
}:
{
  imports = [
    ./brew.nix
    ./macos-apps.nix
  ];

  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.overlays = [
    nixpkgs-overlay.overlays.default
    (final: prev: {

      # TODO:
      nixos-rebuild-ng = prev.nixos-rebuild-ng.overrideAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
      });
    })
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  nix = {
    # linux-builder = {
    #   enable = true;
    #   systems = [
    #     "x86_64-linux"
    #     "aarch64-linux"
    #   ];
    #   config.boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
    # };

    settings = {
      trusted-users = [ "@admin" ];
      auto-optimise-store = true;
      log-format = "multiline-with-logs";
      sandbox = true;

      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
    };

    gc.automatic = true;

    channel.enable = false;
  };

  # User setup
  system.primaryUser = "rishab";
  users.users."rishab" = {
    name = "rishab";
    home = "/Users/rishab";
    shell = pkgs.fish;
  };

  # Fish shell setup
  programs.fish.enable = true;
  environment.shells = [
    pkgs.fish
  ];

  # Use Touch ID or Apple Watch for sudo auth
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 7;

  system.startup.chime = true;

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;

      tilesize = 54;
      largesize = 70;

      show-recents = false;

      wvous-tl-corner = 10; # Put display to sleep
      wvous-tr-corner = 13; # Lock Screen

      expose-group-apps = true;
      launchanim = true;
      mineffect = "scale";
      orientation = "bottom";

      showDesktopGestureEnabled = true;
      showLaunchpadGestureEnabled = true;

      persistent-apps = [
        {
          app = "/Applications/Zen Browser.app";
        }
        {
          app = "${pkgs.ghostty-bin}/Applications/Ghostty.app";
        }
        {
          app = "${pkgs.spotify}/Applications/Spotify.app";
        }
        {
          app = "${pkgs.obsidian}/Applications/Obsidian.app";
        }
        {
          app = "${pkgs.logseq}/Applications/Logseq.app";
        }
        {
          app = "${pkgs.thunderbird}/Applications/Thunderbird.app";
        }
        {
          app = "${pkgs.devonthink}/Applications/DEVONthink 3.app";
        }
        {
          app = "${pkgs.signal-desktop}/Applications/Signal.app";
        }
        {
          app = "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app";
        }
        {
          app = "/Applications/Telegram.app";
        }
        {
          app = "${pkgs.vesktop}/Applications/Vesktop.app";
        }
        {
          app = "${pkgs.lightning-matrix-client}/Applications/Lightning.app";
        }
        {
          app = "/Applications/Strongbox.app";
        }
      ];
    };

    hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXRemoveOldTrashItems = false;
      NewWindowTarget = "Documents";
      ShowHardDrivesOnDesktop = false;
      ShowExternalHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = false;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

    iCal = {
      CalendarSidebarShown = true;
      "first day of week" = "System Setting";
    };

    menuExtraClock = {
      FlashDateSeparators = false;
      IsAnalog = false;
      Show24Hour = true;
      ShowDate = 0; # When space allows
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
    };

    ActivityMonitor = {
      IconType = 0;
      OpenMainWindow = true;
      ShowCategory = 100;
    };

    LaunchServices.LSQuarantine = true; # TODO: do i need quarantine
  };

  time.timeZone = "Europe/Berlin";

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      ipv4_servers = true;
      ipv6_servers = true;

      dnscrypt_servers = true;
      doh_servers = true;
      odoh_servers = false;

      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      http3 = true;
      http3_probe = false;

      bootstrap_resolvers = [
        "9.9.9.11:53"
        "149.112.112.11:53"
        "[2620:fe::11]:53"
        "[2620:fe::fe:11]:53"
      ];

      sources = {
        public-resolvers = {
          urls = [
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          ];
          cache_file = "public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        quad9-resolvers = {
          urls = [
            "https://quad9.net/dnscrypt/quad9-resolvers.md"
            "https://raw.githubusercontent.com/Quad9DNS/dnscrypt-settings/main/dnscrypt/quad9-resolvers.md"
          ];
          cache_file = "quad9-resolvers.md";
          minisign_key = "RWQBphd2+f6eiAqBsvDZEBXBGHQBJfeG6G+wJPPKxCZMoEQYpmoysKUN";
          prefix = "quad9-";
        };
        relays = {
          urls = [
            "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
          ];
          cache_file = "relays.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };

      forwarding_rules = pkgs.writeText "forwarding-rules.conf" ''
        fritz.box                 $DHCP
        iceportal.de              $DHCP
      '';

      monitoring_ui = {
        enabled = true;
        enable_query_log = true;
        listen_address = "127.0.0.1:6969";
        privacy_level = 1;
      };
    };
  };

  launchd.daemons.dnscrypt-proxy.serviceConfig.UserName = lib.mkForce "root";

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "USB 10/100/1000 LAN"
    ];
    dns = [
      "::1"
      "127.0.0.1"
    ];
  };
}
