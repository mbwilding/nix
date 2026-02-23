{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
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
        config.allowUnfree = true;
        overlays = [
          inputs.neovim-nightly-overlay.overlays.default
          (final: prev: {
            caelestia-cli-oled =
              inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default.overrideAttrs
                (old: {
                  patchPhase =
                    (old.patchPhase or "")
                    + ''
                      mkdir -p src/caelestia/data/schemes/oled/default
                      cp ${./modules/home/caelestia-schemes/oled/default/dark.txt} \
                        src/caelestia/data/schemes/oled/default/dark.txt
                    '';
                });
            caelestia-shell-oled =
              inputs.caelestia-shell.packages.${system}.caelestia-shell.override {
                withCli = true;
                caelestia-cli = final.caelestia-cli-oled;
              };
          })
        ];
      };

      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs secrets; };

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
                  hostname
                  secrets
                  ;
              };
              home-manager.users.anon = {
                imports = [
                  ./home.nix
                  inputs.plasma-manager.homeModules.plasma-manager
                  inputs.caelestia-shell.homeManagerModules.default
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
              hostname
              secrets
              ;
          };

          modules = [
            ./home.nix
            inputs.plasma-manager.homeModules.plasma-manager
            inputs.caelestia-shell.homeManagerModules.default
          ];
        }
      );
    };
}
