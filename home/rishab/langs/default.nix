{ config, ... }: {
  imports = [
    ./java.nix
  ];

  programs.go = {
    enable = true;
    env = {
      GOPATH = "${config.xdg.dataHome}/go";
      GOBIN = "${config.xdg.dataHome}/go/bin";
    };
  };

  programs.uv = {
    enable = true;
    python = {
      prune = true;
      versions = [
        "3.14"
      ];
    };
    tool = {
      packages = [ ];
      prune = true;
    };
  };

}
