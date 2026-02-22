{ ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # portalPackage = {};
  };

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
}
