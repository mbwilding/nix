{
  inputs,
  lib,
  secrets,
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
    symlinkDir =
      base: ignore:
      lib.listToAttrs (
        map
          (file: {
            name = lib.removePrefix (toString base + "/") (toString file);
            value = {
              source = file;
            };
          })
          (
            lib.filter (
              f: !lib.any (pattern: lib.hasInfix pattern (toString f)) (if ignore == null then [ ] else ignore)
            ) (lib.filesystem.listFilesRecursive base)
          )
      );

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          {
            nixpkgs.hostPlatform = lib.mkDefault system;
            nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.default ];

            nix = {
              nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
              settings = {
                access-tokens = "github.com=${secrets.githubPersonalToken}";
                substituters = [ "https://attic.xuyh0120.win/lantian" ];
                trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
                extra-substituters = [ "https://noctalia.cachix.org" ];
                extra-trusted-public-keys = [
                  "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
                ];
              };
            };

            _module.args.pkgsMaster = inputs.nixpkgs-master.legacyPackages.${system};
          }
        ];
      };
    };

    mkNixOnDroid = name: {
      ${name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import inputs.nixpkgs-droid { system = "aarch64-linux"; };
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
          modules = [
            inputs.self.modules.homeManager.mbwilding
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
