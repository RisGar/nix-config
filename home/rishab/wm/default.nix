{
  config,
  lib,
  ...
}:
{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    settings = fromTOML (builtins.readFile ./aerospace.toml) // {
      # Make PiP follow workspace
      exec-on-workspace-change = [
        (lib.getExe config.programs.fish.package)
        ./workspace-change.fish
      ];
    };
  };

}
