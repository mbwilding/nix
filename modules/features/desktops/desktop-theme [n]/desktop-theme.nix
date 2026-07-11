{ ... }:

{
  flake.modules.homeManager.desktop-theme =
    { pkgs, ... }:
    {
      gtk = {
        enable = true;
        theme = {
          name = "Breeze-Dark";
          package = pkgs.kdePackages.breeze-gtk;
        };
        gtk4.theme = {
          name = "Breeze-Dark";
          package = pkgs.kdePackages.breeze-gtk;
        };
      };

      home.pointerCursor = {
        enable = true;
        name = "breeze_cursors";
        package = pkgs.kdePackages.breeze;
        gtk.enable = true;
        x11.enable = true;
      };

      qt = {
        enable = true;
        style = {
          name = "breeze";
          package = pkgs.kdePackages.breeze;
        };
        platformTheme.name = "gtk3";
      };

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
}
