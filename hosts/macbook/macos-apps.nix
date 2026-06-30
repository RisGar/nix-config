{ lib, ... }:

# macOS 27 (build 26A428) attributes a window to an application through the
# bundle of the *launched* main executable. nixpkgs instead puts a trampoline at
# that path — a bash script or a `makeWrapper` binary — that `exec`s a hidden
# `.<name>-wrapped` binary, and the hand-over loses the association:
# LaunchServices reports the app with `pid == -1` (or drops it from
# `NSWorkspace.runningApplications`), AeroSpace never learns the PID, and
# `aerospace list-windows --all` / `list-apps` show nothing for an app whose
# windows are perfectly real. Apps whose bundle already keeps its identity are
# unaffected (Ghostty, Spotify, Obsidian, DEVONthink, Zen, Telegram). Details and
# measurements: lib/macos-app-fix.nix.
#
# lib/macos-app-fix.nix rebuilds a bundle in the layout macOS accepts and
# re-exposes what the trampoline exported through `Info.plist`'s `LSEnvironment`.
# The `env` below is what each trampoline sets, taken from the generated
# wrappers. Plugin/library search paths tolerate equivalent values, so the lists
# are rebuilt from the same packages rather than hardcoding store paths.
#
# `mpv` is deliberately absent: its trampoline passes `--script=` arguments to
# the real binary, which LSEnvironment cannot reproduce (lib/macos-app-fix.nix
# refuses that case loudly). Its scripts would have to move into
# `~/.config/mpv/scripts/` first.
{
  # `lib.mkAfter` is load-bearing. `nixpkgs-overlay` (listed in
  # hosts/macbook/default.nix) also assigns `logseq`, and nix-darwin orders an
  # imported module's overlay list entries *before* the importing module's own.
  # Without mkAfter this overlay ran first, so `nixpkgs-overlay`'s assignment
  # replaced the repaired bundle with the raw one again and AeroSpace went on
  # ignoring Logseq's windows.
  nixpkgs.overlays = lib.mkAfter [
    (
      final: prev:
      let
        fix = import ../../lib/macos-app-fix.nix {
          inherit lib;
          pkgs = final;
        };
      in
      {
        thunderbird = fix {
          src = prev.thunderbird;
          app = "Thunderbird.app";
          executable = "${prev.thunderbird}/Applications/Thunderbird.app/Contents/MacOS/.thunderbird-old";
          env = {
            MOZ_APP_LAUNCHER = "thunderbird";
            MOZ_LEGACY_PROFILES = "1";
            MOZ_ALLOW_DOWNGRADE = "1";
            # The trampoline *prepends* to the session's values; LSEnvironment
            # sets a variable outright, so the conventional system paths are
            # spelled out as well (makeBinPath also carries gnupg, which the
            # profile's `withExternalGnupg` needs).
            PATH = "${
              lib.makeBinPath [
                prev.gnupg
                prev.thunderbird
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
            LD_LIBRARY_PATH = lib.makeLibraryPath [
              prev.gpgme
              prev.krb5
              prev.ffmpeg
            ];
          };
        };
      }
    )
  ];
}
