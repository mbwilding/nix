{
  inputs,
  lib,
  pkgsMaster,
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

  config.flake.lib =
    let
      user = "mbwilding";
      secrets = import ../_secrets.nix;
      sharedNixSettings = {
        access-tokens = [ "github.com=${secrets.githubPersonalToken}" ];
        trusted-users = [ user ];
        extra-substituters = [
          "https://attic.xuyh0120.win/lantian"
          "https://noctalia.cachix.org"
        ];
        extra-trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
        max-jobs = 1;
        # cores = 2;
      };
    in
    {
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

      mkNixOS = system: name: {
        ${name} = inputs.nixpkgs.lib.nixosSystem {
          modules = [
            inputs.self.modules.nixos.${name}
            {
              nixpkgs.hostPlatform = lib.mkDefault system;
              nixpkgs.overlays = [
                inputs.nix-cachyos-kernel.overlays.default
              ];

              nix = {
                nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
                settings = sharedNixSettings;
              };

              _module.args.pkgsMaster = inputs.nixpkgs-master.legacyPackages.${system};
              _module.args.pkgsStable = inputs.nixpkgs-stable.legacyPackages.${system};
            }
          ];
        };
      };

      mkFeatures =
        features:
        {
          nixos = lib.filter (m: m != null) (
            map (name: inputs.self.modules.nixos.${name} or null) features
          );
          homeManager = lib.filter (m: m != null) (
            map (name: inputs.self.modules.homeManager.${name} or null) features
          );
        };

      mkHomeManager = system: name: extraModules: {
        ${name} = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          modules = [
            inputs.self.modules.homeManager.${user}
            (
              { pkgs, ... }:
              {
                nix.package = lib.mkDefault pkgs.nix;
                nix.settings = sharedNixSettings;

                nixpkgs.config.allowUnfree = true;
                _module.args.secrets = secrets;
                _module.args.pkgsMaster = inputs.nixpkgs-master.legacyPackages.${system};
                _module.args.pkgsStable = inputs.nixpkgs-stable.legacyPackages.${system};
              }
            )
          ]
          ++ extraModules;
        };
      };

      mkNixOnDroid = name: {
        ${name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import inputs.nixpkgs-droid { system = "aarch64-linux"; };
          modules = [
            inputs.self.modules.nixOnDroid.${name}
            {
              nix.extraOptions = ''
                extra-substituters = ${builtins.concatStringsSep " " sharedNixSettings.extra-substituters}
                extra-trusted-public-keys = ${builtins.concatStringsSep " " sharedNixSettings.extra-trusted-public-keys}
              '';
            }
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
