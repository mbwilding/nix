{ ... }:

{
  flake.modules.nixos.amd = {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    services = {
      xserver.videoDrivers = [ "amdgpu" ];
    };

    environment = {
      sessionVariables = {
        ENABLE_HDR_WSI = 1;
        LIBVA_DRIVER_NAME = "radeonsi";
        VDPAU_DRIVER = "radeonsi";
      };
    };
  };
}
