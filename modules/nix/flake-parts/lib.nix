{
  inputs,
  lib,
  ...
}:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  options.flake.nixOnDroidConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };

    mkNixOnDroid = name: {
      ${name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import inputs.nixpkgs { system = "aarch64-linux"; };
        modules = [ inputs.self.modules.nixOnDroid.${name} ];
        extraSpecialArgs = { inherit inputs; };
      };
    };

    mkHomeManager =
      let
        secrets = import ../_secrets.nix;
      in
      system: name: extraModules: {
        ${name} = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            hostname = name;
          };
          modules = [
            inputs.self.modules.homeManager.anon
            {
              nixpkgs.config.allowUnfree = true;
              _module.args.secrets = secrets;
              _module.args.pkgsMaster = inputs.nixpkgs-master.legacyPackages.${system};
            }
          ]
          ++ extraModules;
        };
      };
  };
}
