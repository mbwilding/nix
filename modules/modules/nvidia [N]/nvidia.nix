{ ... }:

{
  flake.modules.nixos.nvidia =
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
        };
      };

      services = {
        xserver.videoDrivers = [ "nvidia" ];
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
    };
}
