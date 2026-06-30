{
  description = "nix-darwin and nixos system flake";

  outputs =
    {
      sops-nix,
      direnv-instant,
      disko,
      home-manager,
      homebrew-cask,
      homebrew-core,
      lix-module,
      nix-darwin,
      nix-homebrew,
      nix-index-database,
      nixpkgs,
      nixpkgs-overlay,
      self,
      stylix,
      zen-browser,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # Upstream fixes we depend on, carried as the patches of the GitHub PRs
      # (vendored in patches/) until nixos-unstable ships them. Delete an entry
      # as soon as the channel has it.
      patches = [
        ./patches/573101-go-mockery-3.8.1.patch # TODO: https://nixpk.gs/pr-tracker.html?pr=573101
        ./patches/572466-zotero-firefox-esr-140.patch # TODO: https://nixpk.gs/pr-tracker.html?pr=572466
        # e2e tests start an interactive bash that sources /etc/bashrc (unsandboxed
        # darwin builds), which resets PATH and makes the shell integration run the
        # host's atuin instead of the one under test
        ./patches/574509-atuin-e2e-nosysbashrc.patch # TODO: https://nixpk.gs/pr-tracker.html?pr=574509
        ./patches/574509-atuin-e2e-bash-wrapper.patch # TODO: https://nixpk.gs/pr-tracker.html?pr=574509
      ];

      # The pinned nixpkgs with the patches above applied. It is applied to the
      # darwin configuration only, since `patch` runs with the target system's
      # stdenv and a machine cannot realise another platform's tree.
      nixpkgs-patched =
        system:
        (import nixpkgs { inherit system; }).applyPatches {
          name = "nixpkgs-patched";
          src = nixpkgs;
          inherit patches;
        };
    in
    {
      # Build darwin flake using:
      # $ sudo -i darwin-rebuild build --flake .#Rishabs-MacBook-Pro
      darwinConfigurations."Rishabs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          home-manager.darwinModules.default
          nix-homebrew.darwinModules.default
          sops-nix.darwinModules.sops
          lix-module.darwinModules.default

          ./hosts/macbook

          {
            nixpkgs.source = nixpkgs-patched "aarch64-darwin"; # pending nixpkgs PRs, see patches/
            nix.registry.nixpkgs.flake = nixpkgs; # Pin flake so nix3 commands use system nixpkgs
            nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; # pin nix path so nix2 commands use system nixpkgs

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users."rishab" = ./home/rishab;
              backupFileExtension = "bak";

              extraSpecialArgs = {
                inherit
                  stylix
                  sops-nix
                  direnv-instant
                  nix-index-database
                  nixpkgs-overlay
                  zen-browser
                  disko
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
              mutableTaps = false;
            };
          }

        ];
        specialArgs = {
          inherit
            sops-nix
            self
            nixpkgs-overlay
            ;
        };
      };

      nixosConfigurations."Rishabs-Homelab" = lib.nixosSystem {
        modules = [
          disko.nixosModules.default
          sops-nix.nixosModules.sops

          ./hosts/homelab
        ];
        specialArgs = {
        };
      };

      nixosConfigurations."study-usb" = lib.nixosSystem {
        modules = [
          ./hosts/study-usb
        ];
        specialArgs = {
        };
      };

      # Expose fully configured system packages including overlays under config#packages
      legacyPackages."aarch64-darwin" = self.darwinConfigurations."Rishabs-MacBook-Pro".pkgs;
      legacyPackages."x86_64-linux" = self.nixosConfigurations."Rishabs-Homelab".pkgs;
      nix.registry.config.flake = self;
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
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    disko = {
      url = "github:nix-community/disko/pull/1277/head"; # TODO wait for merge
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixpkgs-overlay = {
      url = "github:RisGar/nixpkgs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
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
  };
}
