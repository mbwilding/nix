{ pkgs, ... }:

{
  programs = {
    appimage.enable = true;
    appimage.binfmt = true;
    appimage.package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.icu
        pkgs.libxcrypt-legacy
        pkgs.python312
        pkgs.python312Packages.torch
      ];
    };
  };
}
