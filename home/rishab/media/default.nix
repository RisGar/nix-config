{ pkgs, config, ... }: {
  xdg.configFile."mpv/fonts/modernz-icons.ttf".source = ./modernz-icons.ttf;
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      autoload
      thumbfast
      # thumbfast-vanilla-osc
      modernz
    ];
    config = {
      # Video & Rendering
      profile = "high-quality";
      vo = "gpu-next";
      gpu-api = "vulkan";
      gpu-context = "macvk";
      hwdec = "auto-safe";
      target-colorspace-hint = true;

      ## Behavior (personal preference)
      keep-open = "yes";
      save-position-on-quit = true;
      watch-later-options-remove = "sub-pos";

      # Track selection
      slang = "en,eng,enm";
      alang = "ja,jp,jpn,en,eng";

      # Caching
      cache = "yes";
      demuxer-max-bytes = "3GiB";
      demuxer-max-back-bytes = "128MiB";
      demuxer-readahead-secs = 60;
      #cache-secs=30

      ### Deband
      deband = "no";
      deband-iterations = 4;
      deband-threshold = 48;
      deband-range = 64;
      deband-grain = 12;

      # Subtitles
      sub-ass-override = "no"; # Toggle with 'k'
      sub-font = "Cabin";
      sub-font-size = 50;
      sub-color = "#FFFFFFFF";
      sub-margin-y = 40;
      sub-border-size = 2.4;
      sub-border-color = "#FF000000";
      sub-shadow-color = "#A0000000";
      sub-shadow-offset = 0.8;
      sub-bold = "yes";
      sub-ass-style-overrides = "playresx=1920,playresy=1080,Kerning=yes";
      sub-ass = true;

      # Screenshots
      screenshot-format = "jxl";
      screenshot-png-compression = 9;
      screenshot-high-bit-depth = "no";
      screenshot-dir = "${config.xdg.userDirs.pictures}/mpv/";
      screenshot-template = "%F-%wH_%wM_%wS_%#02n";

      # Logging
      msg-module = true;

      # UI
      osc = "no";
      title-bar = "no";
    };
    bindings = {
      k = "cycle-values sub-ass-override 'yes' 'force' 'no'"; # toggle overriding SSA/ASS subtitle styles with the normal styles
      o = "cycle video-unscaled";
      l = "cycle-values loop-file 'inf' 'no'"; # toggle infinite looping
      v = "cycle sub-visibility"; # hide or show the subtitles

      # Audio
      WHEEL_UP = "add volume 5";
      WHEEL_DOWN = "add volume -5";
      UP = "add volume 5";
      DOWN = "add volume -5";

      # Seek
      WHEEL_LEFT = "seek -10";
      WHEEL_RIGHT = "seek 10";
      LEFT = "seek -5";
      RIGHT = "seek 5";
      "Alt+LEFT" = "add chapter -1";
      "Alt+RIGHT" = "add chapter 1";
      "Ctrl+Alt+LEFT" = "no-osd sub-seek -1";
      "Ctrl+Alt+RIGHT" = "no-osd sub-seek 1";

      # Key Controls
      ENTER = "cycle fullscreen";

      # Filtering
      h = "cycle deband";
      p = "cycle interpolation";
    };
  };

  services.jellyfin-mpv-shim = {
    enable = true;
  };
}
