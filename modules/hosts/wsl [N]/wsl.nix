{ inputs, ... }:

{
  flake.modules.nixos.wsl =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-base
        fonts
        user-anon
        docker
      ] ++ [
        inputs.nixos-wsl.nixosModules.default
      ];

      home-manager.sharedModules = [
        inputs.self.modules.homeManager.theme
        ./_shells.nix
      ];

      wsl.enable = true;
      wsl.defaultUser = "anon";

      networking.hostName = "wsl";

      programs.zsh.enable = false;

      system.stateVersion = "25.11";

      home-manager.users.anon.home.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "wsl";

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "wsl" [
    inputs.self.modules.homeManager.theme
    ./_shells.nix
  ];
}
