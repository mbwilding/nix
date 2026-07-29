{ ... }:

{
  flake.modules.homeManager.chrome =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.google-chrome.override {
          commandLineArgs = builtins.concatStringsSep " " [
            # Ozone / Wayland
            "--ozone-platform=wayland"

            # VAAPI hardware video decode/encode (needed for UniFi Protect
            # "Enhanced" HEVC camera streams via nvidia-vaapi-driver)
            "--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL,CanvasOopRasterization,PlatformHEVCDecoderSupport"
            "--disable-features=UseChromeOSDirectVideoDecoder"
            "--enable-accelerated-mjpeg-decode"
            "--enable-accelerated-video-decode"
            "--enable-zero-copy"

            # ANGLE-GL backend required for nvidia-vaapi-driver's GL/VAAPI interop
            "--use-gl=angle"
            "--use-angle=gl"
            "--ignore-gpu-blocklist"
            "--disable-gpu-driver-bug-workarounds"
            "--disable-gpu-driver-workarounds"
            "--disable-gpu-vsync"
            "--disable-software-rasterizer"
            "--enable-gpu-compositing"
            "--enable-gpu-rasterization"
            "--enable-oop-rasterization"
            "--canvas-oop-rasterization"
            "--enable-raw-draw"
            "--use-cmd-decoder=validating"
            "--use-vulkan"

            # Misc
            "--disable-font-subpixel-positioning"
          ];
        })
      ];
    };
}
