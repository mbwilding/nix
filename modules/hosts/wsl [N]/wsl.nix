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

      # Inject Breeze Dark theming for GUI apps running under WSL (no DE).
      home-manager.sharedModules = [ inputs.self.modules.homeManager.theme ];

      wsl.enable = true;
      wsl.defaultUser = "anon";

      networking.hostName = "wsl";

      programs.zsh.enable = false;

      system.stateVersion = "25.05";

      # Override HM stateVersion for WSL
      home-manager.users.anon.home.stateVersion = lib.mkForce "25.05";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "wsl";
}
