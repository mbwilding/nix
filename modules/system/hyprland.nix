{ pkgs, lib, ... }:

{
  programs = {
    hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
  };

  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   extraConfig = "plugin = ${inputs.hy3.packages.${pkgs.system}.hy3}/lib/libhy3.so ";
  # };

  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = with pkgs; {
          command = "${tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${hyprland}/share/wayland-sessions";
          user = "greeter";
        };
      };
    };

    # Dolphin mounts
    udisks2.enable = true;

    xserver.enable = false;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    configPackages = with pkgs; [ hyprland ];
    config = {
      hyprland = {
        default = [
          "hyprland"
          "kde"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [
          "kde"
          "gtk"
        ];
        "org.freedesktop.impl.portal.AppChooser" = [
          "kde"
          "gtk"
        ];
      };
      common = {
        default = [
          "hyprland"
          "kde"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [
          "kde"
          "gtk"
        ];
        "org.freedesktop.impl.portal.AppChooser" = [
          "kde"
          "gtk"
        ];
      };
    };
  };

  environment = {
    etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

    systemPackages = with pkgs; [
      hyprpolkitagent
      kdePackages.kactivitymanagerd
      kdePackages.ark
    ];
  };
}
