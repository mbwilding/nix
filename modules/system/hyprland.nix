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

    xserver.enable = false;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
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

  security.rtkit.enable = true;
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    hyprpolkitagent
  ];
}
