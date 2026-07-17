{ inputs, ... }:

{
  flake.modules.homeManager.gui = {
    imports = with inputs.self.modules.homeManager; [
      discord
      dolphin
      jetbrains
      kitty
      obs
      onlyoffice
      packages-gui
      power-platform-toolbox
      reaper
      steam
      teams
      wine
      yabridge
    ];
  };
}
