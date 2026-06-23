lib:

lib.listToAttrs (
  lib.map (name: lib.nameValuePair (lib.removeSuffix ".age" name) { file = ./${name}; }) (
    lib.attrNames (import ./secrets.nix)
  )
)
