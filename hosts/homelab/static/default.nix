{
  pkgs,
  ...
}:
let
  # drop html/assets into ./files; everything there is served as-is, e.g.
  # ./files/quiz.html -> static.rishab.org/quiz.html
  content = ./files;
  # ./files is gitignored (see .gitignore), so a fresh checkout may not have it;
  # serve an empty root rather than failing the whole Caddyfile build.
  copyContent =
    if builtins.pathExists content then
      "cp -r ${content}/. $out/\nrm -f $out/.gitkeep"
    else
      "";
  site = pkgs.runCommand "static-site" { } ''
    mkdir -p $out
    ${copyContent}
  '';
in
{
  # generic static file hosting
  apps."static" = {
    content = ''
      root * ${site}
      encode
      file_server
    '';
  };
}
