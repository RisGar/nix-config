{
  description = "nix-darwin and nixos system flake";

  outputs =
    {
      homebrew-cask,
      homebrew-core,
      agenix,
      direnv-instant,
      disko,
      home-manager,
      mlpreview,
      nix-darwin,
      nix-homebrew,
      nix-index-database,
      nixln-edit,
      nixpkgs,
      nvim-config,
      self,
      virby,
      ocrtool-mcp,
      stylix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      secrets = import ./secrets lib;
    in
    {
      # Build darwin flake using:
      # $ sudo -i darwin-rebuild build --flake .#Rishabs-MacBook-Pro
      darwinConfigurations."Rishabs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          virby.darwinModules.default
          home-manager.darwinModules.default
          nix-homebrew.darwinModules.default
          agenix.darwinModules.default

          ./hosts/macbook

          {
            nix.registry.nixpkgs.flake = nixpkgs; # Pin flake so nix3 commands use system nixpkgs
            nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; # pin nix path so nix2 commands use system nixpkgs

            age.secrets = secrets;

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users."rishab" = ./home/rishab;
              backupFileExtension = "bak";

              extraSpecialArgs = {
                inherit
                  stylix
                  agenix
                  direnv-instant
                  nix-index-database
                  ocrtool-mcp
                  secrets
                  ;
              };
            };

            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = "rishab";
              autoMigrate = true;
              # Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              # mutableTaps = true;
            };
          }

        ];
        specialArgs = {
          inherit
            agenix
            mlpreview
            self
            nixln-edit
            nvim-config
            ;
        };
      };

      nixosConfigurations."Rishabs-Homelab" = lib.nixosSystem {
        modules = [
          disko.nixosModules.default
          agenix.nixosModules.default

          ./hosts/homelab

          {
            age.secrets = secrets;
          }
        ];
        specialArgs = {
        };
      };
    };

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mlpreview = {
      url = "github:RisGar/mlpreview";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    nixln-edit = {
      url = "github:nlintn/nixln-edit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:RisGar/nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    base16-schemes = {
      url = "github:RisGar/base16-schemes";
      flake = false;
    };
    virby = {
      url = "github:quinneden/virby-nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ocrtool-mcp = {
      url = "github:RisGar/ocrtool-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
