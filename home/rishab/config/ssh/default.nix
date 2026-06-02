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

      # TODO
      "hostinger" = {
        Hostname = "89.117.169.136";
        User = "u797478303";
        Port = 65002;
        IdentityFile = "~/.ssh/hostinger";
        ServerAliveInterval = 240;
      };

      "gargnas" = {
        Hostname = "gargnas.internal";
        User = "Rishab";
        Port = 223;
      };

      "lxhalle" = {
        Hostname = "lxhalle.cit.tum.de";
        User = "gargr";
      };

      "proxmox" = {
        Hostname = "proxmox.internal";
        User = "root";
      };

      "debian" = {
        Hostname = "debian.internal";
        User = "docker";
      };

      "homelab" = {
        Hostname = "homelab.internal";
        User = "rishab";
      };

      "valhalla" = {
        Hostname = "valhalla.fs.tum.de";
        User = "garg";
      };

      "itsec" = {
        Hostname = "sandkasten.sec.in.tum.de";
        User = "team-263";
      };

      "pangolin" = {
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
