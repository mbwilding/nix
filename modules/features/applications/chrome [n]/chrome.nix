{ ... }:

{
  flake.modules.homeManager.chrome =
    {
      lib,
      pkgs,
      osConfig ? null,
      ...
    }:
    let
      isNvidia = osConfig != null && lib.elem "nvidia" (osConfig.services.xserver.videoDrivers or [ ]);
    in
    {
      home.packages = [
        (pkgs.google-chrome.override {
          commandLineArgs = builtins.concatStringsSep " " (
            [
              "--canvas-oop-rasterization"
              "--disable-features=UseChromeOSDirectVideoDecoder"
              "--disable-font-subpixel-positioning"
              "--disable-gpu-driver-bug-workarounds"
              "--disable-gpu-driver-workarounds"
              "--disable-gpu-vsync"
              "--disable-software-rasterizer"
              "--enable-accelerated-mjpeg-decode"
              "--enable-accelerated-video-decode"
              "--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL,CanvasOopRasterization,PlatformHEVCDecoderSupport${lib.optionalString isNvidia ",VaapiOnNvidiaGPUs"}"
              "--enable-gpu-compositing"
              "--enable-gpu-rasterization"
              "--enable-oop-rasterization"
              "--enable-raw-draw"
              "--enable-zero-copy"
              "--ignore-gpu-blocklist"
              "--ozone-platform=wayland"
            ]
            ++ lib.optionals isNvidia [
              "--use-angle=gl"
              "--use-cmd-decoder=validating"
              "--use-gl=angle"
            ]
          );
        })
      ];
    };
}
