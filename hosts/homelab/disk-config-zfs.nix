{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            priority = 2;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };

    zpool = {
      zroot = {
        type = "zpool";

        rootFsOptions = {
          compression = "zstd";
          xattr = "sa";
          acltype = "posixacl";
          atime = "off";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
