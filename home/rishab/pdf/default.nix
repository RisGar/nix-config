{
  pkgs,
  lib,
  ...
}:
let
  # On macOS sioyek resolves `shaders/`, `prefs.config`, `keys.config` and
  # `tutorial.pdf` relative to `Contents/Resources` of its bundle
  # (`configure_paths()`, the `Q_OS_MACOS` branch in pdf_viewer/main.cpp), while
  # nixpkgs' darwin `postInstall` installs them next to the executable in
  # `Contents/MacOS/`. Every one of those lookups fails.
  #
  # It also fails quietly, which is what makes it look like a rendering bug:
  # `verify_paths()` prints "Error: shader_path: ... doesn't exist!" on stdout,
  # `LoadShaders()` returns 0 for every shader in `initializeGL()` because
  # `read_file_contents()` returns "" for a file it cannot open, and with all GL
  # programs at 0 `glUseProgram(0)` draws nothing. Any file opens in a blank
  # window, with no error beyond those path lines.
  #
  # nixpkgs still does this on master (checked
  # pkgs/by-name/si/sioyek/package.nix), so link the copies it does install into
  # the location the binary actually reads. The real files stay in
  # `Contents/MacOS`, where `bin/sioyek` points and where the Qt wrapper around
  # `.sioyek-wrapped` is generated.
  sioyekBundle = pkgs.sioyek.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        app="$out/Applications/sioyek.app/Contents"
        mkdir -p "$app/Resources"

        for file in shaders prefs.config keys.config tutorial.pdf; do
          if [ -e "$app/MacOS/$file" ] && [ ! -e "$app/Resources/$file" ]; then
            ln -s "../MacOS/$file" "$app/Resources/$file"
          fi
        done
      '';
  });

  # macOS 27 only attributes a window to the bundle whose
  # `Contents/MacOS/<CFBundleExecutable>` is the process image itself.
  # `wrapQtAppsHook` instead leaves a `makeBinaryWrapper` trampoline at that path
  # which `exec`s `.sioyek-wrapped`, so LaunchServices reports
  # `info.sioyek.sioyek` with `pid == -1` (measured with a `CGWindowList` /
  # `NSWorkspace` probe: the windows are real, the PID is not) and AeroSpace
  # lists none of the app's windows. lib/macos-app-fix.nix rebuilds the bundle in
  # the layout macOS accepts and moves the trampoline's environment into
  # `Info.plist`'s `LSEnvironment`; it is the same repair Thunderbird gets in
  # hosts/macbook/macos-apps.nix.
  #
  # `env` is what the generated wrapper exports: it `--prefix`es these lists onto
  # the session's values, while `LSEnvironment` sets them outright, so the
  # complete value has to be spelled out here. Nothing in a normal session sets
  # either variable, and the lists are rebuilt from the same Qt modules rather
  # than hardcoded. nixpkgs' hook also puts an `…-only-plugins-qml` variant of
  # qtbase on `QT_PLUGIN_PATH`; that directory is a symlink to qtbase's own
  # plugins (checked in the store), which is listed here already.
  sioyek = (import ../../../lib/macos-app-fix.nix { inherit lib pkgs; }) {
    src = sioyekBundle;
    app = "sioyek.app";
    executable = "${sioyekBundle}/Applications/sioyek.app/Contents/MacOS/.sioyek-wrapped";
    env = {
      QT_PLUGIN_PATH = lib.makeSearchPath "lib/qt-6/plugins" (
        with pkgs.qt6;
        [
          qtbase
          qtsvg
          qtdeclarative
          qtquick3d
          qtmultimedia
          qt3d
          qtspeech
        ]
      );
      NIXPKGS_QT6_QML_IMPORT_PATH = lib.makeSearchPath "lib/qt-6/qml" (
        with pkgs.qt6;
        [
          qtdeclarative
          qtquick3d
          qtmultimedia
          qt3d
          qtspeech
        ]
      );
    };
  };
in
{
  programs.sioyek = {
    enable = true;
    package = sioyek;
    bindings = {
      "toggle_custom_color" = "i";
      # `<Ctrl h>` is not sioyek's key syntax; it wants `<C-h>`. The parser also
      # splits a binding on whitespace and keeps the last token as the key, so
      # `<Ctrl h>` was read as the command "goto_prev_tab <Ctrl" and dropped.
      "goto_prev_tab" = "<C-h>";
      "goto_next_tab" = "<C-l>";

      "toggle_freehand_drawing_mode" = "d";
    };
    config = {
      "ui_font" = "Maple Mono NF";
      "font_size" = "15";
      "page_separator_width" = "15";
      "page_separator_color" = "0.5 0.5 0.5";

      startup_commands = [ "fit_to_page_width" ];

    };
  };
}
