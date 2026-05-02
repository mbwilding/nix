{ inputs, ... }:

{
  flake.modules.nixos.mpv =
    { ... }:
    {
      # Avoid building rusty-v8/deno from source until Hydra catches up.
      # yt-dlp gained a deno dependency for YouTube JS support (2025-11-12);
      # disable it until the new deno version is available in the binary cache.
      nixpkgs.overlays = [
        (_final: prev: {
          yt-dlp = prev.yt-dlp.override { javascriptSupport = false; };
        })
      ];

      home-manager.sharedModules = [
        inputs.self.modules.homeManager.mpv
      ];
    };

  flake.modules.homeManager.mpv =
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
    };
}
