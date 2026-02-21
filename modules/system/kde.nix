{ pkgs, ... }:

{
  services = {
    xserver.enable = false;

    desktopManager.plasma6.enable = true;

    displayManager = {
      plasma-login-manager = {
        enable = true;
        settings = {
          Users = {
            ReuseSession = false;
          };
          Greeter = {
            WallpaperPluginId = "org.kde.color";
            Color = "0,0,0";
          };
        };
      };
      defaultSession = "plasmawayland";
      # sddm = {
      #   wayland.enable = true;
      #   enable = true;
      # };
    };
  };

  environment = {
    systemPackages = with pkgs.kdePackages; [
      plasma-keyboard
    ];
    plasma6.excludePackages = with pkgs.kdePackages; [
      oxygen
      kate
      krohnkite
      konsole
      discover
    ];
  };

  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "au";
  #   variant = "";
  # };
}
