{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.langs.java;
in
{
  options.langs.java = {
    jdks = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        jdk17
        jdk21
        jdk25
      ];
      description = "java packages to use";
    };
  };

  config = {

    home.activation =
      lib.listToAttrs
      <| lib.map (
        jdk:
        lib.nameValuePair "java-${lib.versions.major jdk.version}" (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            target_root="$HOME/Library/Java/JavaVirtualMachines"
            run mkdir -p "$target_root"

            run ln -sfn $VERBOSE_ARG \
              "${jdk.outPath}/Library/Java/JavaVirtualMachines/zulu-${lib.versions.major jdk.version}.jdk" \
            "$target_root/zulu-${lib.versions.major jdk.version}.jdk"
          ''
        )
      )
      <| cfg.jdks;

    home.sessionVariables = {
      JAVA_HOME = "$(/usr/libexec/java_home)";
    };
    home.sessionPath = [ "${config.home.sessionVariables.JAVA_HOME}/bin" ];
  };
}
