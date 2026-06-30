{
  disko.devices = {
    disk.main = {
      device = "/dev/vda";
      type = "disk";
      imageSize = "10G";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
            priority = 1;
          };

          swap = {
            size = "2G";
            content = {
              type = "swap";
              discardPolicy = "both";
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
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
          mountpoint = "none";
          xattr = "sa";
          acltype = "posixacl";
          atime = "off";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
