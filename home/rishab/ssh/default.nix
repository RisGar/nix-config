{
  config,
  pkgs,
  lib,
  ...
}:
{

  home.file.".strongbox/agent.sock".source = config.lib.file.mkOutOfStoreSymlink (
    config.home.homeDirectory + "/Library/Group Containers/group.strongbox.mac.mcguill/agent.sock"
  );

  home.sessionVariables."SSH_AUTH_SOCK" = config.home.homeDirectory + "/.strongbox/agent.sock";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Host *" = {
        IdentityAgent = "${config.home.homeDirectory}/.strongbox/agent.sock";
        StrictHostKeyChecking = "accept-new";
      };

      "lxhalle" = {
        Hostname = "lxhalle.cit.tum.de";
        User = "gargr";
      };

      "homelab" = {
        Hostname = "ssh.rishab.org";
        User = "rishab";
        ProxyCommand = "${lib.getExe pkgs.cloudflared} access ssh --hostname %h";
      };

      "valhalla" = {
        Hostname = "valhalla.fs.tum.de";
        User = "garg";
      };

      "vps" = {
        Hostname = "85.215.138.48";
        User = "root";
      };
    };
  };
}
