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
        exiftool
        clippy-mac
        ffmpeg
        mediainfo
        imagemagick
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
        mediainfo
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
            id = "mactag";
            url = "*";
            run = "mactag";
          }
          {
            id = "mactag";
            url = "*/";
            run = "mactag";
          }
        ];

        prepend_preloaders = [
          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }

          # Adobe Photoshop is image/adobe.photoshop, already handled above
          # Adobe Illustrator
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
          {
            mime = "application/illustrator";
            run = "mediainfo";
          }
          {
            mime = "application/dvb.ait";
            run = "mediainfo";
          }
          {
            mime = "application/vnd.adobe.illustrator";
            run = "mediainfo";
          }
          {
            mime = "image/x-eps";
            run = "mediainfo";
          }
          {
            mime = "application/eps";
            run = "mediainfo";
          }

          # Sometimes AI file is recognized as "application/pdf". Lmao.
          # In this case use file extension instead:
          {
            url = "*.{ai,eps,ait}";
            run = "mediainfo";
          }

          # Hide metadata by default.
          # Example for image mimetype:
          {
            mime = "{image}/*";
            run = "mediainfo --no-metadata";
          }

          # Hide image preview by default.
          # Example for video mimetype:
          {
            mime = "{video}/*";
            run = "mediainfo --no-preview";
          }

          # NOTE: Use both --no-metadata and --no-preview will display nothing. :)
          # Make sure both of your previewers and preloaders has the same arguments (--no-metadata and --no-preview)
        ];

        prepend_previewers = [
          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }

          # Adobe Photoshop is image/adobe.photoshop, already handled above
          # Adobe Illustrator
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
          {
            mime = "application/illustrator";
            run = "mediainfo";
          }
          {
            mime = "application/dvb.ait";
            run = "mediainfo";
          }
          {
            mime = "application/vnd.adobe.illustrator";
            run = "mediainfo";
          }
          {
            mime = "image/x-eps";
            run = "mediainfo";
          }
          {
            mime = "application/eps";
            run = "mediainfo";
          }

          # Sometimes AI file is recognized as "application/pdf". Lmao.
          # In this case use file extension instead:
          {
            url = "*.{ai,eps,ait}";
            run = "mediainfo";
          }

          # Hide metadata by default.
          # Example for image mimetype:
          {
            mime = "{image}/*";
            run = "mediainfo --no-metadata";
          }

          # Hide image preview by default.
          # Example for video mimetype:
          {
            mime = "{video}/*";
            run = "mediainfo --no-preview";
          }

          # NOTE: Use both --no-metadata and --no-preview will display nothing. :)
          # Make sure both of your previewers and preloaders has the same arguments (--no-metadata and --no-preview)
        ];
      };

      # There are more extensions, mime types which are supported by mediainfo.
      # Just add file's MIME type to `previewers`, `preloaders` above.
      # https://mediaarea.net/en/MediaInfo/Support/Formats
      # If it's not working, file an issue at https://github.com/boydaihungst/mediainfo.yazi/issues
      # For a large file like Adobe Illustrator, Adobe Photoshop, etc
      # you may need to increase the memory limit if no image is rendered.
      # https://yazi-rs.github.io/docs/configuration/yazi#tasks
      tasks = {
        image_alloc = 1073741824; # = 1024*1024*1024 = 1024MB
      };
    };
  };
}
