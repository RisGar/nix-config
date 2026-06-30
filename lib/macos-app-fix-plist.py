#!/usr/bin/env python3
"""Copy an app's Info.plist, injecting LSEnvironment, and print CFBundleExecutable.

Companion to macos-app-fix.nix. `LSEnvironment` is what makes the fix work: the
nixpkgs trampoline used to `export` these variables before `exec`ing the real
binary, and macOS re-applies them for apps it launches itself.
"""

import json
import plistlib
import sys


def main() -> None:
    src_plist, dst_plist, env_file = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(src_plist, "rb") as handle:
        info = plistlib.load(handle)

    env = {}
    if env_file != "-":
        with open(env_file) as handle:
            env = json.load(handle)

    if env:
        info["LSEnvironment"] = env
    else:
        info.pop("LSEnvironment", None)

    with open(dst_plist, "wb") as handle:
        plistlib.dump(info, handle, sort_keys=False)

    sys.stdout.write(info["CFBundleExecutable"])


if __name__ == "__main__":
    main()
