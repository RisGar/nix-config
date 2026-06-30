{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  config = {
    boot = {
      loader.grub = {
        zfsSupport = true;
        efiSupport = false;
      };

      supportedFilesystems = [ "zfs" ];

      zfs.forceImportRoot = true;
      kernelParams = [ "zfs.zfs_arc_max=134217728" ]; # Limit ZFS ARC to 128MB to prevent RAM starvation on 1GB VPS
    };

    services.zfs.autoScrub.enable = true;
    services.zfs.autoScrub.interval = "weekly";

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
      ];
    };

    networking = {
      hostName = "vps";
      hostId = "b637fd6f"; # Random hostId needed for ZFS

      firewall = {
        enable = false;
        allowedTCPPorts = [
          22
          80
          443
          2333
        ];
      };
    };

    services.rathole = {
      enable = true;
      role = "server";
      settings = {
        server = {
          bind_addr = "0.0.0.0:2333";
          transport = {
            type = "noise";
            noise = {
              pattern = "Noise_KK_25519_ChaChaPoly_BLAKE2s";
            };
          };
          services = {
            http_passthrough = {
              bind_addr = "0.0.0.0:80";
            };
            https_passthrough = {
              bind_addr = "0.0.0.0:443";
            };
          };
        };
      };
    };

  };
}
