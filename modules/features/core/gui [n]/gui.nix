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
      reaper
      teams
      thunar
      wine
      yabridge
    ];
  };

  flake.modules.homeManager.packages-gui =
    { pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
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
        ];
      };
    };
}
