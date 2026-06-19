{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "vm";
in
{
  flake.modules.nixos.vm =
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

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName [
    inputs.self.modules.homeManager.kde
  ];
}
