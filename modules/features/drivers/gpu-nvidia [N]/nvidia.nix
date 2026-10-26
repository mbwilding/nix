{ inputs, ... }:

{
  flake.modules.nixos.gpu-nvidia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      offload = config.hardware.nvidia.prime.offload.enable;
    in
    {
      boot.blacklistedKernelModules = [ "nouveau" ];

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };

        nvidia = {
          # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
          # package = config.boot.kernelPackages.nvidiaPackages.production;
          package =
            (config.boot.kernelPackages.callPackage "${inputs.nixpkgs-master}/pkgs/os-specific/linux/nvidia-x11" { })
            .production;
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

        sessionVariables = lib.mkIf (!offload) {
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

      nixpkgs.config.cudaSupport = true;
    };

  flake.modules.homeManager.gpu-nvidia =
    {
      osConfig ? null,
      lib,
      ...
    }:
    {
      nixpkgs.config = lib.mkIf (osConfig == null) { cudaSupport = true; };
    };
}
