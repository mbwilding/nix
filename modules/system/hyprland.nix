{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # portalPackage = {};
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
          command = "start-hyprland";
          user = "anon";
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

  security.rtkit.enable = true;
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    hyprpolkitagent
  ];
}
