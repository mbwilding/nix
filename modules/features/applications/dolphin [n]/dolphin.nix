{ ... }:

{
  flake.modules.homeManager.dolphin =
    { pkgs, ... }:

    {
      home = {
        packages = with pkgs; [
          kdePackages.dolphin
          kdePackages.kio-extras
          kdePackages.kdegraphics-thumbnailers
          kdePackages.ffmpegthumbs
          kdePackages.kimageformats
          kdePackages.qtimageformats

          # Optional, for PDFs
          poppler

          # Optional, for RAW camera images
          libraw

          # Optional, for EPUB/comic archives, etc.
          kdePackages.kio
        ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/bmp" = "imv.desktop";
          "image/svg+xml" = "imv.desktop";
          "image/tiff" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/x-icon" = "imv.desktop";
          "video/3gpp" = "mpv.desktop";
          "video/3gpp2" = "mpv.desktop";
          "video/mp4" = "mpv.desktop";
          "video/mpeg" = "mpv.desktop";
          "video/ogg" = "mpv.desktop";
          "video/quicktime" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "video/x-matroska" = "mpv.desktop";
          "video/x-msvideo" = "mpv.desktop";
          "video/x-ms-wmv" = "mpv.desktop";
        };
      };
    };
}
