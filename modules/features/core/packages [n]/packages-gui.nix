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
            postman
            blender
            bolt-launcher
            cameractrls-gtk4
            google-chrome
            imhex
            imv
            keymapp
            pavucontrol
            prismlauncher
            qbittorrent
            spotify
            tigervnc
            wev
          ];
      };
    };
}
