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
          "https://cache.nixos-cuda.org"
          "https://yazi.cachix.org"
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        max-jobs = 1;
        # cores = 2;
      };
      mkHomeManagerFor = moduleName: work: system: name: extraModules: {
        ${name} = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.self.lib.overlays.hyprlandGlaze
            ];
          };
          modules = [
            inputs.self.modules.homeManager.${moduleName}
            (
              { pkgs, ... }:
              {
                nix.package = lib.mkDefault pkgs.nix;
                nix.settings = sharedNixSettings;

                nixpkgs.config.allowUnfree = true;
                _module.args.secrets = secrets;
                _module.args.work = work;
                _module.args.pkgsMaster = import inputs.nixpkgs-master {
                  inherit system;
                  config.allowUnfree = true;
                };
                _module.args.pkgsStable = import inputs.nixpkgs-stable {
                  inherit system;
                  config.allowUnfree = true;
                };
              }
            )
          ]
          ++ extraModules;
        };
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

              _module.args.pkgsMaster = import inputs.nixpkgs-master {
                inherit system;
                config.allowUnfree = true;
              };
              _module.args.pkgsStable = import inputs.nixpkgs-stable {
                inherit system;
                config.allowUnfree = true;
              };
            }
          ];
        };
      };

      mkFeatures = features: {
        nixos = lib.filter (m: m != null) (map (name: inputs.self.modules.nixos.${name} or null) features);
        homeManager = lib.filter (m: m != null) (
          map (name: inputs.self.modules.homeManager.${name} or null) features
        );
      };

      mkHomeManager =
        system: name: extraModules:
        let
          isWork = builtins.getEnv "USER" == secrets.workId;
        in
        mkHomeManagerFor (if isWork then "work" else user) isWork system name extraModules;
    };
}
