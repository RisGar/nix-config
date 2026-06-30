{
  lib,
  pkgs,
}:

# nixpkgs wraps many GUI apps' main executable with a trampoline: a bash script
# or a `makeWrapper`-produced binary that `exec`s a renamed, hidden binary
# (`.Foo-wrapped`). `exec` hands the process over, so the process that ends up
# owning the app's windows no longer presents itself as the bundle's declared
# main executable.
#
# macOS 27 (build 26A428) attributes a window to an application through the
# bundle of the *launched* main executable. For a trampoline that association is
# lost, and LaunchServices reports the app with `pid == -1` (or leaves it out of
# `NSWorkspace.runningApplications` altogether). AeroSpace then never learns the
# PID, so `aerospace list-windows --all` / `list-apps` show nothing for an app
# whose windows are perfectly real. Measured on macOS 27: a real Mach-O copy and
# a symlink to a binary inside *or outside* the bundle all register correctly; a
# bash `exec` trampoline does not.
#
# This rebuilds the bundle in the layout macOS accepts:
#
#   * `Contents/MacOS/<CFBundleExecutable>` becomes a *symlink* to the real
#     binary (verified working on macOS 27, including for targets outside the
#     bundle; the same approach nixpkgs' `writeDarwinBundle` uses),
#   * the rest of the bundle is symlinked into place so relative lookups
#     (Resources/, Frameworks/, XUL, …) keep resolving,
#   * whatever the trampoline exported is re-exposed through `Info.plist`'s
#     `LSEnvironment`, which macOS 27 still honours for apps it launches.
#
# It refuses to build when the trampoline passed *arguments* to the real binary
# (`--add-flags`): argv cannot be reproduced via LSEnvironment, so such a package
# needs a different fix rather than a silently broken one.
#
# See also: nixpkgs PR #249268 (`writeDarwinBundle` moved off shell wrappers for
# the same class of reason) and WezTerm's "binaries inside the bundle so
# LaunchServices is happy".
{
  # Package providing the bundle to fix.
  src,
  # Bundle directory name inside `src/Applications`, e.g. "Logseq.app".
  app,
  # Store path of the binary that must become the main executable.
  executable,
  # Environment the trampoline exported for the app. macOS *sets* these
  # variables, so a variable the session already defines (e.g. PATH) has to be
  # given a complete value here.
  env ? { },
}:

let
  name = lib.removeSuffix ".app" app;
  srcApp = "${src}/Applications/${app}";
  envFile = pkgs.writeText "lsenvironment-${name}.json" (builtins.toJSON env);
in
pkgs.runCommandLocal "macos-app-fix-${name}"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    meta = src.meta or { };
  }
  ''
    set -euo pipefail

    srcApp=${lib.escapeShellArg srcApp}
    srcPkg=${lib.escapeShellArg "${src}"}
    realBinary=${lib.escapeShellArg executable}
    bundle="$out/Applications/${app}"

    test -e "$realBinary" || {
      echo "error: ${name}: main executable $realBinary does not exist" >&2
      exit 1
    }

    # Rewrites Info.plist (adding LSEnvironment) and reports the executable the
    # bundle declares. Must run before the bundle is populated.
    mkdir -p "$bundle/Contents/MacOS"
    mainExecutable=$(
      python3 ${./macos-app-fix-plist.py} \
        "$srcApp/Contents/Info.plist" "$bundle/Contents/Info.plist" ${envFile}
    )

    trampoline="$srcApp/Contents/MacOS/$mainExecutable"
    if [ "$(readlink -f "$realBinary")" = "$(readlink -f "$trampoline")" ]; then
      echo "error: ${name}: 'executable' is the trampoline itself ($mainExecutable); nothing would change" >&2
      exit 1
    fi
    if [ -f "$trampoline" ] && grep -qa -- '--add-flags' "$trampoline"; then
      echo "error: ${name}: the trampoline passes arguments to the real binary, which" >&2
      echo "       LSEnvironment cannot reproduce; this package needs a different fix" >&2
      exit 1
    fi

    # Mirror the package's other outputs (bin, share, further bundles, …) so the
    # result stays a drop-in replacement for `src`.
    mkdir -p "$out/Applications"
    for entry in "$srcPkg"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      base=$(basename "$entry")
      if [ "$base" = Applications ]; then
        for other in "$entry"/*; do
          [ -e "$other" ] || [ -L "$other" ] || continue
          otherBase=$(basename "$other")
          [ "$otherBase" = "${app}" ] && continue
          ln -s "$other" "$out/Applications/$otherBase"
        done
      else
        ln -s "$entry" "$out/$base"
      fi
    done

    # Everything in the bundle except the two entries handled here is symlinked,
    # so resources and nested helpers keep resolving.
    for entry in "$srcApp"/Contents/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      base=$(basename "$entry")
      case "$base" in
        MacOS | Info.plist) continue ;;
      esac
      ln -s "$entry" "$bundle/Contents/$base"
    done

    # Contents/MacOS is rebuilt too: the real binary is often a hidden sibling
    # of the trampoline (`.Logseq-wrapped`), and launchers such as Thunderbird's
    # resolve helpers relative to their own directory.
    shopt -s dotglob nullglob
    for entry in "$srcApp"/Contents/MacOS/*; do
      ln -s "$entry" "$bundle/Contents/MacOS/$(basename "$entry")"
    done
    shopt -u dotglob nullglob

    # The fix: a symlink instead of the trampoline, so `proc_pidpath` reports a
    # path macOS can map back to this bundle.
    ln -sfn "$realBinary" "$bundle/Contents/MacOS/$mainExecutable"

    echo "fixed ${name}: $mainExecutable -> $realBinary"
  ''
