{
  options,
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    package = options.programs.yazi.package.default.override {
      extraPackages = with pkgs; [
        clippy-mac
        exiftool
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "y" ];
          run = [
            "yank"
            "plugin clippy"
          ];
        }

        {
          on = [
            "b"
            "a"
          ];
          run = "plugin mactag add";
          desc = "Tag selected files";
        }
        {
          on = [
            "b"
            "r"
          ];
          run = "plugin mactag remove";
          desc = "Untag selected files";
        }

        {
          on = [
            "c"
            "m"
          ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }

        {
          on = [ "<C-n>" ];
          run = "shell -- drag %h";
          desc = "open in dragterm";
        }
        {
          on = [ "<C-p>" ];
          run = "shell -- qlmanage -p %s";
          desc = "open in quicklook";
        }

        {
          on = [
            "g"
            "r"
          ];
          run = "shell -- ya emit cd '$(git rev-parse --show-toplevel)'";
          desc = "go to git root";
        }
      ];
    };

    plugins = {
      inherit (pkgs.yaziPlugins)
        full-border
        clippy
        mactag
        chmod
        ;
    };

    initLua = ./init.lua;
    settings = {
      mgr = {
        show_hidden = true;
      };

      plugin = {
        prepend_fetchers = [
          {
            url = "*";
            run = "mactag";
            group = "mactag";
          }
          {
            url = "*/";
            run = "mactag";
            group = "mactag";
          }
        ];

        prepend_preloaders = [
        ];

        prepend_previewers = [
        ];
      };
    };
  };
}
