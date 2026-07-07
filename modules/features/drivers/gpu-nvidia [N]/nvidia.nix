{ ... }:

{
  flake.modules.nixos.gpu-nvidia =
    {
      config,
      pkgs,
      ...
    }:
    {
      # Disabled: forces a global derivation hash change that causes blender, openusd, and
      # other CUDA-capable packages to build from source (no Hydra cache coverage).
      # OptiX is available without this and is the preferred GPU renderer in blender.
      # nixpkgs.config.cudaSupport = true;

      boot.blacklistedKernelModules = [ "nouveau" ];

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };

        nvidia = {
          # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
          package = config.boot.kernelPackages.nvidiaPackages.production;
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
          LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
        };
      };
    };
}
