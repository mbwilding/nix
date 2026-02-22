{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

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
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      nur,
      hyprland,
      hyprland-plugins,
      plasma-manager,
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
        config.packageOverrides = pkgs: {
          nur = import nur {
            inherit pkgs;
          };
        };
      };

      pkgsStable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        config.packageOverrides = pkgs: {
          nur = import nur {
            inherit pkgs;
          };
        };
      };

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs pkgsStable secrets; };

          modules = [
            { nixpkgs.pkgs = pkgs; }

            ./hosts/${hostname}/configuration.nix

            hyprland.nixosModules.default

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit inputs pkgsStable hostname secrets;
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

          extraSpecialArgs = { inherit inputs pkgsStable hostname secrets; };

          modules = [
            ./home.nix
            plasma-manager.homeModules.plasma-manager
          ];
        }
      );
    };
}
