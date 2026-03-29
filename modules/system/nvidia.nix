{ config, pkgs, ... }:

{
  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      open = true;

      modesetting.enable = true;

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    # Load nvidia driver for Xorg and Wayland
    xserver.videoDrivers = [ "nvidia" ];
    # pulseaudio.support32Bit = true;
  };

  environment = {
    systemPackages = with pkgs; [
      nvidia-vaapi-driver
    ];

    sessionVariables = {
      ENABLE_HDR_WSI = 1;
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      VDPAU_DRIVER = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_GSYNC_ALLOWED = 1;
      __GL_VRR_ALLOWED = 1;
    };
  };
}
