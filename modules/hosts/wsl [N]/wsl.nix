{ inputs, ... }:

{
  flake.modules.nixos.wsl =
    { lib, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-base
        fonts
        user-anon
      ] ++ [
        inputs.nixos-wsl.nixosModules.default
      ];

      home-manager.sharedModules = [ inputs.self.modules.homeManager.theme ];

      wsl.enable = true;
      wsl.defaultUser = "anon";

      networking.hostName = "wsl";

      programs.zsh.enable = false;

      system.stateVersion = "25.11";

      home-manager.users.anon.home.stateVersion = lib.mkForce "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "wsl";
}
