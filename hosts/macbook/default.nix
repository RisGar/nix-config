{
  agenix,
  lib,
  mlpreview,
  nixln-edit,
  nvim-config,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./brew.nix
  ];

  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
    permittedInsecurePackages = [
      # TODO: remove when fixed
      "electron-39.8.10"
    ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.overlays = [
    agenix.overlays.default
    mlpreview.overlays.default

    (final: prev: {
      clippy-mac = prev.callPackage ../../pkgs/clippy-mac.nix { };
      thaw = prev.callPackage ../../pkgs/thaw.nix { };
      mole-mac = prev.callPackage ../../pkgs/mole-mac.nix { }; # TODO: fix
      dragterm = prev.callPackage ../../pkgs/dragterm.nix { };

      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;

      whatsapp-for-mac = prev.whatsapp-for-mac.overrideAttrs (old: rec {
        version = "2.26.22.20";
        src = prev.fetchzip {
          extension = "zip";
          name = "WhatsApp.app";
          url = "https://web.whatsapp.com/desktop/mac_native/release/?version=${version}&extension=zip&configuration=Release&branch=master";
          hash = "sha256-tEE590f8h6rO2BBLjBxrrZx+i8fGHct1ojOJf2M/vQM=";
        };
      });

      nvim = prev.callPackage nvim-config {
        jdks = with prev; [
          jdk17
          jdk21
          jdk25
        ];
      };

      nixln-edit = prev.callPackage nixln-edit { };

      yaziPlugins = prev.yaziPlugins // {
        clippy = prev.callPackage (
          {
            fetchFromGitHub,
          }:
          prev.yaziPlugins.mkYaziPlugin {
            pname = "clippy.yazi";
            version = "0-unstable-2025-08-25";

            installPhase = ''
              runHook preInstall

              cp -r . $out

              runHook postInstall
            '';

            src = fetchFromGitHub {
              owner = "Gallardo994";
              repo = "clippy.yazi";
              rev = "8ce55413976ebd1922dbc4fc27ced9776823df54";
              hash = "sha256-oB9DkNWvUDbSAPnxtv56frlWWYz5vtu2BJVvWH/Uags=";
            };

            meta = {
              description = "Clippy integration for Yazi file manager";
              homepage = "https://github.com/Gallardo994/clippy.yazi";
              license = lib.licenses.mit;
            };
          }
        ) { };
      };
    })
  ];

  services.virby = {
    enable = false;
    cores = 4;
    onDemand = {
      enable = true;
      ttl = 15; # in mins
    };
    rosetta = true;
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  nix = {
    package = pkgs.lixPackageSets.stable.lix;
    linux-builder.enable = true;
    optimise.automatic = true;
  };

  # Necessary for using flakes on this system.
  nix.settings = {
    trusted-users = [ "rishab" ];

    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operator"
    ];
  };

  nix.channel.enable = false;

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
          app = "/Applications/Ghostty.app";
        }
        {
          app = "/Applications/Spotify.app";
        }
        {
          app = "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app";
        }
        {
          app = "${pkgs.obsidian}/Applications/Obsidian.app";
        }
        {
          app = "${pkgs.logseq}/Applications/Logseq.app";
        }
        {
          app = "/System/Applications/Mail.app";
        }
        {
          app = "/System/Applications/Calendar.app";
        }
        {
          app = "/Applications/DEVONthink 3.app";
        }
        {
          app = "/Applications/Telegram.app";
        }
        {
          app = "${pkgs.vesktop}/Applications/Vesktop.app";
        }
        {
          app = "${pkgs.cinny-desktop}/Applications/Cinny.app";
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

      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      http3 = true;

      sources = {
        public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        relays = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
            "https://download.dnscrypt.info/resolvers-list/v3/relays.md'"
          ];
          cache_file = "relays.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };

      forwarding_rules = ../common/forwarding-rules.conf;

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
