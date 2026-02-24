{ ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      fs = "no";
      force-seekable = "yes";
      loop-playlist = "inf";
      loop-file = "inf";
      vo = "gpu-next";
      target-colorspace-hint = "yes";
      target-colorspace-hint-mode = "source";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
    };
    bindings = {
      r = "cycle_values video-rotate 90 180 270 0";
    };
  };
}
