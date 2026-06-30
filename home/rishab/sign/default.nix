{ config, lib, ... }:
let
  cfg = config.sign;
in
{
  options.sign = {
    gpgKey = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "gpg key to use for signing";
    };
    sshKey = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "ssh key to use for signing";
    };

  };

  config = {
    sign = {
      gpgKey = "0745F38FB14A92A8";
      sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmBZ3bwIN+dktLVqVRq8DxFuz8Obm0dEt3wr1+ahTHQ";
    };

    programs.gpg = {
      enable = true;
    };

    assertions = [
      {
        assertion = lib.strings.hasPrefix "ssh-" cfg.sshKey;
        message = "ssh key should start with 'ssh-'";
      }
    ];

  };
}
