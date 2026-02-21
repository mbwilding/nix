{ ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # portalPackage = {};
  };

  services = {
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
