{ lib, ... }:
{
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
            PATH = "${
              lib.makeBinPath [
                final.gnupg
                prev.thunderbird
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
            LD_LIBRARY_PATH = lib.makeLibraryPath [
              final.gpgme
              final.krb5
              final.ffmpeg
            ];
          };
        };
      }
    )
  ];
}
