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
