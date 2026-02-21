{ ... }:

{
  # Enable hardware acceleration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    # Load AMDGPU driver for Xorg and Wayland
    xserver.videoDrivers = [ "amdgpu" ];
  };

  environment = {
    sessionVariables = {
      ENABLE_HDR_WSI = 1;
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };
}
