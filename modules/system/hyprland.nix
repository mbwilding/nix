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
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.hyprland}/share/wayland-sessions";
          user = "greeter";
        };
      };
    };

    # Dolphin mounts
    udisks2.enable = true;
    # Dolphin previews
    tumbler.enable = true;

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
    extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.hyprland ];
    config = {
      hyprland = {
        default = [ "hyprland" ];
      };
      common = {
        default = [ "hyprland" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    hyprpolkitagent
    kdePackages.kactivitymanagerd
  ];
}
