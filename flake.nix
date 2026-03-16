{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    ucodenix.url = "github:e-tho/ucodenix";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: Remove once PR is merged: https://github.com/pwr-Solaar/Solaar/pull/3132
    solaar = {
      url = "github:caioquirino/Solaar/feat/pro-x-2-superstrike";
      flake = false;
    };
  };

  outputs =
    { ... }@inputs:
    let
      system = "x86_64-linux";
      hosts = [
        "anon"
        "nona"
        "vm"
      ];

      secrets = import ./modules/system/secrets.nix;

      pkgs = import inputs.nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };

        overlays = [
          inputs.neovim-nightly-overlay.overlays.default
          (final: prev: {
            solaar = prev.solaar.overrideAttrs (_: {
              src = inputs.solaar;
            });
          })
        ];
      };

      font = "CaskaydiaMono Nerd Font Mono";
      # font = "JetBrainsMonoNL Nerd Font";
      # font = "Iosevka Nerd Font";

      pkgsStable = import inputs.nixpkgs-stable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit
              inputs
              pkgsStable
              secrets
              font
              ;
          };

          modules = [
            { nixpkgs.pkgs = pkgs; }

            ./hosts/${hostname}/configuration.nix

            inputs.ucodenix.nixosModules.default

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit
                  inputs
                  pkgsStable
                  hostname
                  secrets
                  font
                  ;
              };

              home-manager.users.anon = {
                imports = [
                  ./home.nix
                  inputs.plasma-manager.homeModules.plasma-manager
                ];
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = inputs.nixpkgs.lib.genAttrs hosts mkHost;

      homeConfigurations = inputs.nixpkgs.lib.genAttrs hosts (
        hostname:

        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit
              inputs
              pkgsStable
              hostname
              secrets
              font
              ;
          };

          modules = [
            ./home.nix

            inputs.plasma-manager.homeModules.plasma-manager
          ];
        }
      );

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust Dev Shell";
        };
      };
    };
}
