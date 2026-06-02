{
  config,
  lib,
  pkgs,
  ...
}:
let
  delta = lib.getExe config.programs.delta.package;
in
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

      gpg.ssh = {
        allowedSignersFile = "${config.home.homeDirectory}/.ssh/git_allowed_signers";
      };

      core = {
        editor = lib.getExe pkgs.nvim;
      };

      merge = {
        conflictstyle = "zdiff3";
      };

      pull = {
        rebase = true;
      };

      init = {
        defaultBranch = "main";
      };

      credential = {
        helper = lib.getExe pkgs.git-credential-manager;
        "https://artemis.tum.de" = {
          provider = "generic";
        };
        "https://git.fs.tum.de" = {
          provider = "generic";
        };
        "https://gitlab.lrz.de" = {
          provider = "generic";
        };
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      dark = true;
      side-by-side = true;
    };
    # TODO: jujutsu
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
    settings = {
      aliases = {
        ".gitignore" = "!gh api -X GET /gitignore/templates/\"$1\" --jq \".source\"";
      };
    };
  };
}
