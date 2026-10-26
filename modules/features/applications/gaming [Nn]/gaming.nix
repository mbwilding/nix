{ inputs, ... }:

{
  flake.modules.nixos.gaming = {
    imports = with inputs.self.modules.nixos; [
      lutris
      steam
    ];
  };

  flake.modules.homeManager.gaming = {
    imports = with inputs.self.modules.homeManager; [
      clonehero
      epic-games-launcher
      heroic
      lutris
      steam
      steam-achievement-manager
    ];
  };
}
