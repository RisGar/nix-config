{
  pkgs,
  lib,
  config,
  ...
}:
{

  imports = [
    ./auth.nix
    ./dashboard.nix
    ./disk-config.nix
    ./dnscrypt-proxy.nix
    ./hardware-configuration.nix
    ./metrics.nix
    ./nfs.nix
    ./samba.nix
    ./transmission.nix
    ./yopass.nix
  ];

  options = {
    vars = lib.mkOption { };
  };

  # nixos-anywhere --flake .#homelab --generate-hardware-config nixos-generate-config ./hosts/homelab/hardware-configuration.nix <hostname>
  config = {

    services.qemuGuest.enable = true;

    nixpkgs.config = {
      allowBroken = true;
      allowUnfree = true;
    };

    boot = {
      loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      growPartition = true;
    };

    environment.systemPackages = with pkgs; [
      vim
      git
      podman-compose
    ];

    # security.sudo.wheelNeedsPassword = false; # Don't ask for passwords
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    programs.ssh.startAgent = true;

    users.users.root = {
      hashedPasswordFile = config.age.secrets.homelab-root.path;
    };

    users.users.rishab = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.homelab-rishab.path;
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

    system.stateVersion = "25.11";

    nix.settings = {
      trusted-users = [
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
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
        options = [ "bind" ];
      };
    };

    networking = {
      hostName = "Rishabs-Homelab";

      firewall.enable = true;

      usePredictableInterfaceNames = true;

      defaultGateway = "192.168.178.1";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
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

    services.newt = {
      enable = true;
      settings = {
        endpoint = "https://pangolin.rishab.org";
        docker-socket = "unix:///var/run/docker.sock";
      };
      environmentFile = config.age.secrets.newt.path;
    };

    services.stirling-pdf = {
      enable = true;
      # environment = {
      #   SECURITY_ENABLELOGIN = "true";
      # };
    };

    services.librespeed = {
      enable = true;
      frontend = {
        enable = true;
        contactEmail = "contact@rishab-garg.de";
        servers = [
          {
            name = "Homelab";
            server = "//speed.rishab.org";
          }
        ];
      };
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

    # services.open-webui = {
    #   enable = true;
    #   port = 1213;
    #   environmentFile = config.age.secrets.open-webui.path;
    # };
  };
}
