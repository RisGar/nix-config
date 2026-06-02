{
  agenix,
  config,
  direnv-instant,
  lib,
  nix-index-database,
  pkgs,
  secrets,
  stylix,
  ...
}:
{
  imports = [
    agenix.homeManagerModules.default
    nix-index-database.homeModules.default
    direnv-instant.homeModules.direnv-instant
    stylix.homeModules.stylix

    ./config/agents
    ./config/aerospace
    ./config/captive-browser # TODO: replace with dnscypt proxy forwarding of firefox default captive portal getter site
    ./config/fastfetch
    ./config/fish
    ./config/fzf
    ./config/git
    ./config/java
    ./config/ssh
    ./config/tmux
    ./config/yazi
    ./config/sioyek
    ./config/colours
  ];

  options = {
    vars = lib.mkOption { };
  };

  config = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home.username = "rishab";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "26.05";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # old behaviour of linking instead of copying into Applications folder
    targets.darwin.linkApps.enable = true;
    targets.darwin.copyApps.enable = false;

    age = {
      inherit secrets;
      identityPaths = [ (config.home.homeDirectory + "/.ssh/agenix") ];
    };

    vars.systemFlake = "/private/etc/nix-darwin";
    vars.hostname = "Rishabs-MacBook-Pro";

    home.packages =
      with pkgs;
      [
        # xquartz
        dragterm
        signal-desktop
        nvim
        # anki
        pdfarranger
        nixln-edit
        monitorcontrol
        bun
        # mole-mac
        cinny-desktop
        pkgs.agenix
        airdrop-cli
        babelfish
        beam.interpreters.erlang_28 # for gleescript
        bear
        captive-browser
        csvlens
        doomrunner
        ffmpeg
        git-credential-manager
        github-copilot-cli
        grandperspective
        http-server
        iina
        isabelle
        julia-bin
        libqalculate
        llvmPackages_latest.clang
        llvmPackages_latest.clang-manpages
        localsend
        logseq
        luarocks
        man-pages
        man-pages-posix
        mlpreview
        moonlight-qt
        mosh
        nix-tree
        nixd
        nixfmt
        nixos-rebuild
        numi
        obsidian # TODO: home manager
        ov
        # papers
        pkgconf
        podman
        podman-compose
        presenterm
        prismlauncher
        raycast
        rustup
        shottr
        stirling-pdf
        suspicious-package
        terminal-notifier
        thaw
        tlrc # tldr rust client
        tokei
        typst
        unison-ucm
        virt-viewer
        wakatime-cli
        whatsapp-for-mac
        xdg-ninja
        xz
        zotero
      ]
      ++
        # Fonts
        [
          maple-mono.NF
          maple-mono.NF-CN
          jost
          raleway
          source-sans
          source-sans-pro
          libertinus
          hanken-grotesk
          carlito
        ];

    fonts.fontconfig.enable = true;

    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };

    programs.zoxide = {
      enable = true;
    };

    programs.uv = {
      enable = true;
    };

    programs.yt-dlp = {
      enable = true;
    };

    programs.bat = {
      enable = true;
      config = {
        pager = "${lib.getExe pkgs.ov} -F -H4";
      };
    };

    programs.fd = {
      enable = true;
    };

    programs.starship = {
      enable = true;
      enableTransience = true;
      settings = fromTOML (builtins.readFile ./config/starship/starship.toml);
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # TODO:
    # programs.direnv-instant = {
    #   enable = true;
    # };

    programs.gpg = {
      enable = true;
    };

    programs.ripgrep = {
      enable = true;
    };

    programs.jq = {
      enable = true;
    };

    programs.go = {
      enable = true;
      env = {
        GOPATH = "${config.xdg.dataHome}/go";
        GOBIN = "${config.xdg.dataHome}/go/bin";
      };
    };

    programs.aria2 = {
      enable = true;
    };

    programs.vesktop = {
      enable = true;
    };

    programs.man = {
      generateCaches = false;
    };

    gtk = {
      enable = true;
      colorScheme = "dark";
      gtk4.theme = config.gtk.theme;
    };

    xdg.configFile."ghostty/config".text = builtins.readFile ./config/ghostty/config;

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
      };
    };

    programs.spotify-player = {
      enable = true;
      settings = {
        enable_audio_visualization = true;
        enable_media_control = true;
        border_type = "Rounded";
        enable_mouse_scroll_volume = false;
        play_icon = " ";
        pause_icon = " ";
        liked_icon = " ";
        device = {
          audio_cache = true;
          normalization = true;
          autoplay = true;
        };
      };
    };

    programs.eza = {
      enable = true;
      colors = "always";
      icons = "always";
      git = true;

      extraOptions = [
        "--classify=always"
        "--group-directories-first"
      ];
    };
  };
}
