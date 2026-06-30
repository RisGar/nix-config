{
  config,
  lib,
  ...
}:
{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    settings = builtins.fromTOML (builtins.readFile ./aerospace.toml) // {
      # Make PiP follow workspace
      exec-on-workspace-change = [
        (lib.getExe config.programs.fish.package)
        ./workspace-change.fish
      ];

      after-startup-command =
        if config.programs.sketchybar.enable then
          [ "exec-and-forget ${lib.getExe config.programs.sketchybar.package}" ]
        else
          [ ];
    };
  };

}
