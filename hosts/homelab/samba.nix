{ config, ... }:
{
  services.samba = {
    enable = true;
    usershares.enable = true;
    openFirewall = true;
    settings = {
      "tm_share" = {
        "path" = "/mnt/external/TimeMachine";
        "valid users" = "rishab";
        "public" = "no";
        "writeable" = "yes";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "1T";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  system.activationScripts = {
    init_smbpasswd.text = ''
      /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${config.age.secrets.user-rishab.path})\n$(/run/current-system/sw/bin/cat ${config.age.secrets.user-rishab.path})\n" | /run/current-system/sw/bin/smbpasswd -sa rishab
    '';
  };
}
