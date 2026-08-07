{ inputs, ... }:

{
  flake.modules.homeManager.gui = {
    imports = with inputs.self.modules.homeManager; [
      chrome
      discord
      jetbrains
      kitty
      obs
      onlyoffice
      packages-gui
      power-platform-toolbox
      reaper
      teams
      thunar
      wine
      yabridge
    ];
  };

  flake.modules.homeManager.packages-gui =
    {
      pkgs,
      ...
    }:
    {
      home = {
        packages =
          let
            github-copilot = pkgs.callPackage ./_github-copilot.nix { };
            powerplatform-toolbox = pkgs.callPackage ./_power-platform-toolbox.nix { };
          in
          with pkgs;
          [
            # Custom
            github-copilot
            powerplatform-toolbox

            # Packages
            # prismlauncher # Minecraft
            _1password-gui
            bolt-launcher
            cameractrls-gtk4
            imhex
            imv
            keymapp
            pavucontrol
            postman
            qbittorrent
            spotify
            tigervnc
            wev
          ];
      };
    };
}
