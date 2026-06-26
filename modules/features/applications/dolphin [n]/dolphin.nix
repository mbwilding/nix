{ ... }:

{
  flake.modules.homeManager.dolphin =
    { pkgs, ... }:

    {
      home = {
        packages = with pkgs; [
          kdePackages.dolphin
          kdePackages.kio-extras
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
    };
}
