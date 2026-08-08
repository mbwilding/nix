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
      config,
      lib,
      pkgs,
      secrets,
      ...
    }:
    let
      github-copilot = pkgs.callPackage ./_github-copilot.nix { };
      powerplatform-toolbox = pkgs.callPackage ./_power-platform-toolbox.nix { };
      isWork = config.home.username == secrets.workId;
    in
    {
      home = {
        packages =
          (with pkgs; [
            # Custom
            powerplatform-toolbox

            # Packages
            # prismlauncher # Minecraft
            _1password-gui
            bolt-launcher
            cameractrls-gtk4
            imhex
            imv
            kdePackages.ark
            keymapp
            pavucontrol
            postman
            qbittorrent
            spotify
            tigervnc
            wev
          ])
          ++ lib.optionals isWork [
            github-copilot
          ];
      };
    };
}
