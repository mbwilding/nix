{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "vm";
  stateVersion = "26.05";

  features = [
    "system-default"
    "user-mbwilding"
  ];

  featureModules = inputs.self.lib.mkFeatures features;
in
{
  flake.modules.nixos.${hostName} =
    { ... }:
    {
      imports = featureModules.nixos ++ [ ./_hardware-configuration.nix ];

      home-manager.sharedModules = featureModules.homeManager;

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName featureModules.homeManager;
}
