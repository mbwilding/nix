{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "wsl";
  stateVersion = "26.05";
  homeManagerModules = [ ./_shells.nix ];
  # secrets = import ../../nix/_secrets.nix;

  features = [
    "appimage"
    "claude-code"
    "cli"
    "development"
    "fonts"
    "proxy"
    "system-base"
    "user-mbwilding"
    "wireshark"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
in
{
  flake.modules.nixos.${hostName} =
    { ... }:
    {
      imports =
        featureModules.nixos
        ++ [
          ./_hardware-configuration.nix
          ./_audio.nix
        ]
        ++ [
          inputs.nixos-wsl.nixosModules.default
        ];

      home-manager.sharedModules = homeManagerModules;

      home-manager.users.mbwilding.home.stateVersion = stateVersion;
      networking.hostName = hostName;
      programs.fish.enable = true;
      programs.zsh.enable = false;
      system.stateVersion = stateVersion;

      nixpkgs.config.allowUnfree = true;

      wsl = {
        defaultUser = "mbwilding";
        enable = true;
      };
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
