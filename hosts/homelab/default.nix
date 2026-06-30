{
  pkgs,
  lib,
  config,
  ...
}:
{

  imports = [
    ./ai.nix
    ./auth.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./metrics.nix
    ./nfs.nix
    ./recipes.nix
    ./samba.nix
    ./torrent.nix
    ./yopass.nix
    ./revserse-proxy.nix
  ];

  options = {
    vars = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    ports = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  # nixos-anywhere --flake .#homelab --generate-hardware-config nixos-generate-config ./hosts/homelab/hardware-configuration.nix <hostname>
  config = {
    boot = {
      loader.systemd-boot = {
        enable = true;
        editor = false;
      };
      loader.efi.canTouchEfiVariables = true;

      supportedFilesystems = [ "zfs" ];
      kernelParams = [ "zfs.zfs_arc_max=6442450944" ];
    };

    services.zfs.autoScrub.enable = true;
    services.zfs.autoScrub.interval = "weekly";

    nixpkgs.overlays = [
    ];

    nixpkgs.config = {
      allowBroken = true;
      allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      vim
      git
    ];

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    users.users.root = {
      hashedPasswordFile = config.age.secrets.user-root.path;
    };

    users.users.rishab = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-rishab.path;
      description = "default user";
      extraGroups = [
        "networkmanager"
        "wheel"
        "podman"
        "samba"
        "users"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmBZ3bwIN+dktLVqVRq8DxFuz8Obm0dEt3wr1+ahTHQ"
      ];
    };

    system.stateVersion = "26.05";

    nix.settings = {
      trusted-users = [
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operator"
      ];
    };

    virtualisation.containers.enable = true;
    virtualisation.oci-containers.backend = "podman";
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    fileSystems = {
      "/mnt/external" = {
        device = "/dev/disk/by-uuid/030f15d4-3c55-403f-b6e1-de2abd2912e0";
        fsType = "ext4";
      };
      "/export/external" = {
        device = "/mnt/external";
        fsType = "none";
        options = [ "bind" ];
      };
    };

    networking = {
      hostName = "Rishabs-Homelab";
      hostId = "a526fc5e";

      firewall.enable = true;

      usePredictableInterfaceNames = true;

      defaultGateway = "192.168.178.1";
      nameservers = [
        "9.9.9.11"
        "149.112.112.11"
      ];

      interfaces.ens18.ipv4.addresses = [
        {
          address = "192.168.178.42";
          prefixLength = 24;
        }
      ];
    };

    security.sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };

    ports.librespeed = 8989;
    # TODO: serve frontend on caddy
    services.librespeed = {
      enable = true;
      domain = "speed.rishab.org";
      settings.listen_port = config.ports.librespeed;
      frontend = {
        enable = true;
        useNginx = false;
        contactEmail = "contact@rishab-garg.de";
      };
    };

    services.caddy.virtualHosts = {
      "speed.rishab.org".extraConfig = ''
        import tinyauth_forwarder
        reverse_proxy 127.0.0.1:${toString config.ports.librespeed}
      '';

    };

    # services.karakeep = {
    #   enable = true;
    # };

    # virtualisation.oci-containers.containers.anilist-mal-sync = {
    #   volumes = [
    #     "tokens:/home/appuser/.config/anilist-mal-sync"
    #   ];
    #   environmentFiles = [ config.age.secrets.anilist-mal-sync.path ];
    #   environment = {
    #     WATCH_INTERVAL = "12h";
    #   };
    #   ports = [ "18080:18080" ];
    #   image = "ghcr.io/bigspawn/anilist-mal-sync:latest";
    # };
  };
}
