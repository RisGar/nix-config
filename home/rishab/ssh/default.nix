{
  config,
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
        IdentityAgent = config.home.homeDirectory + "/.strongbox/agent.sock";
        StrictHostKeyChecking = "accept-new";
      };

      "lxhalle" = {
        Hostname = "lxhalle.cit.tum.de";
        User = "gargr";
      };

      "homelab" = {
        Hostname = "192.168.178.42";
        User = "rishab";
      };

      "valhalla" = {
        Hostname = "valhalla.fs.tum.de";
        User = "garg";
      };

      "vps" = {
        Hostname = "85.215.138.48";
        User = "root";
      };

      "psa" = {
        Hostname = "psa.in.tum.de";
        User = "go57siq";
        ForwardX11Trusted = true;
      };

      "grnvs" = {
        Hostname = "testbed.grnvs.net.cit.tum.de";
        User = "u64829";
        Port = 10022;
        ForwardAgent = true;
      };
    };
  };
}
