{
  description = "neovim config using nixCats";

  inputs = {
    # see :help nixCats.flake.inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nvim-treesitter-main.url = "github:iofq/nvim-treesitter-main";
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    "plugins-nvim-dev-container" = {
      url = "github:esensar/nvim-dev-container";
      flake = false;
    };
  };

  # see :help nixCats.flake.outputs
  outputs =
    {
      nixpkgs,
      nixCats,
      nvim-treesitter-main,
      ...
    }@inputs:
    let
      inherit (nixCats) utils;
      luaPath = ./.;
      forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
      # the following extra_pkg_config contains any values
      # which you want to pass to the config set of nixpkgs
      # import nixpkgs { config = extra_pkg_config; inherit system; }
      # will not apply to module imports
      # as that will have your system values
      extra_pkg_config = {
        # allowUnfree = true;
      };
      # management of the system variable is one of the harder parts of using flakes.

      # so I have done it here in an interesting way to keep it out of the way.
      # It gets resolved within the builder itself, and then passed to your
      # categoryDefinitions and packageDefinitions.

      # this allows you to use ${pkgs.stdenv.hostPlatform.system} whenever you want in those sections
      # without fear.

      #outPath see :help nixCats.flake.outputs.overlays
      dependencyOverlays = # (import ./overlays inputs) ++
        [
          # This overlay grabs all the inputs named in the format
          # `plugins-<pluginName>`
          # Once we add this overlay to our nixpkgs, we are able to
          # use `pkgs.neovimPlugins`, which is a set of our plugins.
          (utils.standardPluginOverlay inputs)
          # add any other flake overlays here.

          # when other people mess up their overlays by wrapping them with system,
          # you may instead call this function on their overlay.
          # it will check if it has the system in the set, and if so return the desired overlay
          # (utils.fixSystemizedOverlay inputs.codeium.overlays
          #   (system: inputs.codeium.overlays.${system}.default)
          # )
          nvim-treesitter-main.overlays.default
          (final: prev: {
            vimPlugins = prev.vimPlugins.extend (
              f: p: {
                nvim-treesitter = p.nvim-treesitter.withAllGrammars; # or withPlugins...
                # also redefine nvim-treesitter-textobjects (any other plugins that depend on nvim-treesitter)
                nvim-treesitter-textobjects = p.nvim-treesitter-textobjects.overrideAttrs {
                  dependencies = [ f.nvim-treesitter ];
                };
              }
            );
          })
        ];

      # see :help nixCats.flake.outputs.categories
      # and
      # :help nixCats.flake.outputs.categoryDefinitions.scheme
      categoryDefinitions =
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkPlugin,
          ...
        }@packageDef:
        {
          # to define and use a new category, simply add a new list to a set here,
          # and later, you will include categoryname = true; in the set you
          # provide when you build the package using this builder function.
          # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

          # lspsAndRuntimeDeps:
          # this section is for dependencies that should be available
          # at RUN TIME for plugins. Will be available to PATH within neovim terminal
          # this includes LSPs
          lspsAndRuntimeDeps = {
            general =
              with pkgs;
              [
                astro-language-server
                bash-language-server
                biome
                docker-language-server
                fish-lsp
                gleam
                jdt-language-server
                lua-language-server
                markdownlint-cli2
                marksman
                prettierd
                ruff
                ty
                stylua
                svelte-language-server
                tailwindcss-language-server
                taplo
                texlab
                tinymist
                vscode-langservers-extracted
                vtsls
                yaml-language-server
              ]
              ++ [
                mermaid-cli # for snacks.image
                tree-sitter # for nvim-treesitter
              ];
          };

          # This is for plugins that will load at startup without using packadd:
          startupPlugins = {
            #TODO:nvim-dap nvim-dap-ui nvim-dap-virtual-text
            general =
              with pkgs.vimPlugins;
              [
                #nvim-dev-container
                #tree-sitter-ghostty
                SchemaStore-nvim
                blink-cmp
                clangd_extensions-nvim
                colorful-menu-nvim
                conform-nvim
                fidget-nvim
                friendly-snippets
                gitsigns-nvim
                lazydev-nvim
                lualine-nvim
                luasnip
                mini-ai
                mini-surround
                nvim-autopairs
                nvim-lint
                nvim-lspconfig
                nvim-treesitter
                nvim-treesitter-context
                nvim-treesitter-textobjects
                nvim-web-devicons
                oil-nvim
                onedarkpro-nvim
                precognition-nvim
                rainbow-delimiters-nvim
                render-markdown-nvim
                snacks-nvim
                todo-comments-nvim
                trouble-nvim
                ts-comments-nvim
                typst-preview-nvim
                vim-be-good
                vim-dadbod
                vim-dadbod-completion
                vim-dadbod-ui
                vim-wakatime
                which-key-nvim
              ]
              ++ (with pkgs.neovimPlugins; [
                nvim-dev-container
              ]);
          };

          # not loaded automatically at startup.
          # use with packadd and an autocommand in config to achieve lazy loading
          optionalPlugins = {
            general = with pkgs.vimPlugins; [
              nvim-jdtls
              rustaceanvim
              vimtex
            ];
          };

          # shared libraries to be added to LD_LIBRARY_PATH
          # variable available to nvim runtime
          sharedLibraries = {
            general = with pkgs; [
              # libgit2
            ];
          };

          # environmentVariables:
          # this section is for environmentVariables that should be available
          # at RUN TIME for plugins. Will be available to path within neovim terminal
          environmentVariables = {
            test = {
              CATTESTVAR = "It worked!";
            };
          };

          # If you know what these are, you can provide custom ones by category here.
          # If you dont, check this link out:
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
          extraWrapperArgs = {
            test = [
              ''--set CATTESTVAR2 "It worked again!"''
            ];
          };

          # lists of the functions you would have passed to
          # python.withPackages or lua.withPackages
          # do not forget to set `hosts.python3.enable` in package settings

          # get the path to this python environment
          # in your lua config via
          # vim.g.python3_host_prog
          # or run from nvim terminal via :!<packagename>-python3
          python3.libraries = {
            test = (_: [ ]);
          };
          # populates $LUA_PATH and $LUA_CPATH
          extraLuaPackages = {
            test = [ (_: [ ]) ];
          };
        };

      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.

      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions = {
        # These are the names of your packages
        # you can include as many as you wish.
        nvim =
          { pkgs, name, ... }:
          {
            # they contain a settings set defined above
            # see :help nixCats.flake.outputs.settings
            settings = {
              suffix-path = true;
              suffix-LD = true;
              wrapRc = true;
              # IMPORTANT:
              # your alias may not conflict with your other packages.
              # aliases = [ "vim" ];
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
            };
            # and a set of categories that you want
            # (and other information to pass to lua)
            categories = {
              general = true;
            };
          };
      };
      # In this section, the main thing you will need to do is change the default package name
      # to the name of the packageDefinitions entry you wish to use as the default.
      defaultPackageName = "nvim";
    in

    # see :help nixCats.flake.outputs.exports
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            extra_pkg_config
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
        # this is just for using utils such as pkgs.mkShell
        # The one used to build neovim is resolved inside the builder
        # and is passed to our categoryDefinitions and packageDefinitions
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # these outputs will be wrapped with ${system} by utils.eachSystem

        # this will make a package out of each of the packageDefinitions defined above
        # and set the default package to the one passed in here.
        packages = utils.mkAllWithDefault defaultPackage;

        # choose your package for devShell
        # and add whatever else you want in it.
        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = [ defaultPackage ];
            inputsFrom = [ ];
            shellHook = '''';
          };
        };

      }
    )
    // (
      let
        # we also export a nixos module to allow reconfiguration from configuration.nix
        nixosModule = utils.mkNixosModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
        # and the same for home manager
        homeModule = utils.mkHomeModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            extra_pkg_config
            nixpkgs
            ;
        };
      in
      {

        # these outputs will be NOT wrapped with ${system}

        # this will make an overlay out of each of the packageDefinitions defined above
        # and set the default overlay to the one named here.
        overlays = utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays extra_pkg_config;
        } categoryDefinitions packageDefinitions defaultPackageName;

        nixosModules.default = nixosModule;
        homeModules.default = homeModule;

        inherit utils nixosModule homeModule;
        inherit (utils) templates;
      }
    );
}
