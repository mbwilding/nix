{ config, pkgs, ... }:

{
  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;

      # Laptop
      # powerManagement = {
      #   enable = true;
      #   finegrained = true;
      # };
      #
      # prime = {
      #   # Make prime offloading work
      #   offload.enable = true;
      #
      #   # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
      #   intelBusId = "PCI:0:2:0";
      #   # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
      #   nvidiaBusId = "PCI:1:0:0";
      # };
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
