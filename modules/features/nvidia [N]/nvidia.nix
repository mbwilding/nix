{ ... }:

{
  flake.modules.nixos.nvidia =
    { config, pkgs, ... }:
    {
      nixpkgs.config.cudaSupport = true;

      boot.blacklistedKernelModules = [ "nouveau" ];

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };

        nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.stable; # beta
          # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          #   version = "610.43.02";
          #   sha256_64bit = "sha256:0qvllxnb20arjhw3bxdz0hw521di9ib75hldzx97gpscpdaa0d1h";
          #   sha256_aarch64 = "sha256:0qvllxnb20arjhw3bxdz0hw521di9ib75hldzx97gpscpdaa0d1h";
          #   openSha256 = "sha256-hP5NVZZ4vGsACHLmUDKq4uckpd/kn1GxCSYnnJfAuBs=";
          #   settingsSha256 = "sha256-0YAhufRgjDW+uR+kjaTb154fibpcDw8QowfrucoZsKE=";
          #   persistencedSha256 = "sha256:0nd0bf2s9b2ic8a0rcscddasddkryx2qf6mx4861bv44wblm513z";
          # };
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
