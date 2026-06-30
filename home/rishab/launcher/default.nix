{ pkgs, ... }: {
  home.packages = with pkgs; [ vicinae ];

  # TODO
  xdg.configFile."vicinae/settings-nix.json".text = builtins.toJSON {
    theme = {
      dark = {
        name = "one-dark";
      };
      light = {
        name = "vicinae-light";
      };
    };
  };
}
