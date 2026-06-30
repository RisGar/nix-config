{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.file.".ssh/git_allowed_signers".text =
    "mail@rishab-garg.de ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmBZ3bwIN+dktLVqVRq8DxFuz8Obm0dEt3wr1+ahTHQ mail@rishab-garg.de";

  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      format = "ssh";
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmBZ3bwIN+dktLVqVRq8DxFuz8Obm0dEt3wr1+ahTHQ";
    };

    lfs.enable = true;

    settings = {
      user = {
        name = "Rishab Garg";
        email = "mail@rishab-garg.de";
      };

      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/git_allowed_signers";

      core.editor = lib.getExe pkgs.nvim;

      merge.conflictstyle = "zdiff3";

      pull.rebase = true;

      init.defaultBranch = "main";

      credential.helper = "osxkeychain";
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "mail@rishab-garg.de";
        name = "Rishab Garg";
      };
      signing = {
        behavior = "drop"; # Lazily sign on push
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmBZ3bwIN+dktLVqVRq8DxFuz8Obm0dEt3wr1+ahTHQ";
        backends.ssh = {
          allowed-signers = "${config.home.homeDirectory}/.ssh/git_allowed_signers";
        };
      };

      ui = {
        diff-editor = [
          (lib.getExe pkgs.nvim)
          "-c"
          "DiffEditor $left $right $output"
        ];
        diff-intructions = false;
        show-cryptographic-signatures = true;
      };

      git = {
        sign-on-push = true;
      };

    };
  };

  programs.jjui = {
    enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    enableJujutsuIntegration = true;
    options = {
      navigate = true;
      dark = true;
      side-by-side = true;
    };
  };

  # xdg.configFile."lazygit/config.yml".source = ./lazygit.yml;
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        overrideGpg = true;
      };
    };
  };

  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-markdown-preview ];
  };

  programs.gh-dash = {
    enable = true;
  };

  home.packages = with pkgs; [
    lazyjj
  ];
}
