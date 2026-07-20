{ ... }:

{
  flake.modules.homeManager.packages-gui =
    {
      pkgs,
      pkgsStable,
      pkgsMaster,
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
            _1password-gui
            blender
            bolt-launcher
            cameractrls-gtk4
            firefox
            google-chrome
            imhex
            imv
            keymapp
            pavucontrol
            postman
            prismlauncher
            qbittorrent
            spotify
            tigervnc
            wev
          ];
      };
    };
}
