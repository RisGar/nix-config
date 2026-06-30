{
  config,
  direnv-instant,
  lib,
  nix-index-database,
  pkgs,
  sops-nix,
  stylix,
  zen-browser,
  nixpkgs-overlay,
  ...
}:
{
  imports = [
    sops-nix.homeModules.sops
    nix-index-database.homeModules.default
    direnv-instant.homeModules.direnv-instant
    stylix.homeModules.stylix
    zen-browser.homeModules.twilight
    nixpkgs-overlay.homeManagerModules.default

    ./agents
    ./browser
    ./colours
    ./fetch
    ./files
    ./fuzzy
    ./langs
    ./mail
    ./pdf
    ./shell
    ./sign
    ./ssh
    ./tmux
    ./vcs
    ./wm
    ./media
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

    sops = {
      age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops" ];
      defaultSopsFile = "${config.vars.systemFlake}/hosts/macbook/secrets.yaml";
      secrets = {
        context7 = { };
        openrouter = { };
      };
    };

    vars.systemFlake = "/private/etc/nix-darwin";
    vars.hostname = "Rishabs-MacBook-Pro";

    home.packages =
      with pkgs;
      [
        nixos-rebuild
        # xquartz # TODO
        airdrop-cli
        aldente
        babelfish
        beamMinimal29Packages.erlang # for gleescript
        bear
        bun
        cinny-desktop
        cloudflared
        csvlens
        ctx7
        doomrunner
        ffmpeg
        github-copilot-cli
        grandperspective
        gzdoom
        http-server
        iina
        isabelle
        julia-bin
        just
        libqalculate # qalc cli
        llvmPackages_latest.clang
        llvmPackages_latest.clang-manpages
        localsend
        logseq
        luarocks
        man-pages
        man-pages-posix
        mediainfo
        mole-mac
        mosh
        nerdfont-cheatsheet
        nix-output-monitor
        nix-tree
        nixd
        nixfmt
        nixln-edit
        numi
        nvim
        obsidian # TODO: home manager
        pdfarranger
        pdftk
        pkgconf
        podman
        podman-compose
        poppler-utils
        presenterm
        print-cli-rs
        prismlauncher
        raycast
        rustup
        shottr
        signal-desktop
        sops
        stirling-pdf
        suspicious-package
        texliveFull
        thaw
        tlrc
        tokei
        typst
        virt-viewer
        wakatime-cli
        whatsapp-for-mac
        whisper-cpp
        xz
        zotero
        ];

    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };

    programs.zoxide = {
      enable = true;
    };

    programs.yt-dlp = {
      enable = true;
    };

    programs.bat = {
      enable = true;
    };

    programs.fd = {
      enable = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.direnv-instant = {
      enable = true;
    };

    programs.ripgrep = {
      enable = true;
    };

    programs.jq = {
      enable = true;
    };

    programs.aria2 = {
      enable = true;
    };

    programs.vesktop = {
      enable = true;
    };

    gtk = {
      enable = true;
      colorScheme = "dark";
    };

    xdg.configFile."ghostty/config".text = builtins.readFile ./terminal/ghostty-config;

    programs.nh = {
      enable = true;
      darwinFlake = config.vars.systemFlake;
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

    programs.halloy = {
      # enable = true;
    };

    # Disable warning
    programs.man.generateCaches = false;

  };
}
