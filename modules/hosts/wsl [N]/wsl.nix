{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "wsl";
in
{
  flake.modules.nixos.${hostName} =
    { ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          system-base
          fonts
          user-mbwilding
          docker
        ]
        ++ [
          inputs.nixos-wsl.nixosModules.default
        ];

      home-manager.sharedModules = [
        ./_shells.nix
      ];

      wsl.enable = true;
      wsl.defaultUser = "mbwilding";

      networking.hostName = hostName;

      programs.zsh.enable = false;

      system.stateVersion = "25.11";

      home-manager.users.mbwilding.home.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName [
    ./_shells.nix
  ];
}
