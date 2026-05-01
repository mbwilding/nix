{ ... }:

{
  flake.modules.homeManager.theme =
    {
      pkgs,
      lib,
      ...
    }:
    let
      cursor_size = 24;
    in
    {
      gtk = {
        enable = true;

        theme = {
          package = pkgs.kdePackages.breeze-gtk;
          name = "Breeze-Dark";
        };

        iconTheme = {
          package = pkgs.kdePackages.breeze-icons;
          name = "breeze-dark";
        };

        cursorTheme = {
          name = "Breeze";
          size = cursor_size;
        };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };

        gtk4.theme = null;
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };

      dconf = {
        enable = lib.mkDefault true;
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Breeze-Dark";
            icon-theme = "breeze-dark";
            cursor-theme = "Breeze";
            cursor-size = cursor_size;
          };
        };
      };


    };
}
