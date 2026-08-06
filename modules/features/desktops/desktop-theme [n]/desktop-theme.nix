{ ... }:

{
  flake.modules.homeManager.desktop-theme =
    { pkgs, ... }:
    {
      home = {
        pointerCursor = {
          enable = true;
          name = "breeze_cursors";
          package = pkgs.kdePackages.breeze;
          gtk.enable = true;
          x11.enable = true;
        };

        file = {
          ".config/kdeglobals".source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
        };
      };

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
        iconTheme = {
          name = "breeze-dark";
          package = pkgs.kdePackages.breeze-icons;
        };
      };

      qt = {
        enable = true;
        style = {
          name = "breeze";
          package = pkgs.kdePackages.breeze;
        };
        platformTheme.name = "gtk3";
      };

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        icon-theme = "breeze-dark";
      };
    };
}
