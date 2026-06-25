{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "vm";
  stateVersion = "25.11";
in
{
  flake.modules.nixos.${hostName} =
    { ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          kde
          system-default
          user-mbwilding
        ]
        ++ [ ./_hardware-configuration.nix ];

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName [
    inputs.self.modules.homeManager.kde
  ];
}
