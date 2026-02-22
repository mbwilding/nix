{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ucodenix.url = "github:e-tho/ucodenix";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nur,
      plasma-manager,
      ucodenix,
      neovim-nightly-overlay,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      hosts = [
        "anon"
        "nona"
        "vm"
      ];

      secrets = import ./modules/system/secrets.nix;

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nur.overlays.default
          neovim-nightly-overlay.overlays.default
        ];
      };

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs secrets; };

          modules = [
            { nixpkgs.pkgs = pkgs; }

            ./hosts/${hostname}/configuration.nix

            ucodenix.nixosModules.default

            home-manager.nixosModules.home-manager
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
                  plasma-manager.homeModules.plasma-manager
                ];
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs hosts mkHost;

      homeConfigurations = nixpkgs.lib.genAttrs hosts (
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
            plasma-manager.homeModules.plasma-manager
          ];
        }
      );
    };
}
