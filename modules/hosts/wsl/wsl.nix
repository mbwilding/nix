{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "wsl";
  stateVersion = "25.11";
  secrets = import ../../nix/_secrets.nix;

  homeManagerModules = [ ./_shells.nix ];
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
          user-work
          docker
        ]
        ++ [
          inputs.nixos-wsl.nixosModules.default
        ];

      home-manager.sharedModules = homeManagerModules;

      home-manager.users.mbwilding.home.stateVersion = stateVersion;
      home-manager.users.${secrets.workId}.home.stateVersion = stateVersion;
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
