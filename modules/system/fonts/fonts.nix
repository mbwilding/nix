{ pkgs, ... }:

let
  neospleen = pkgs.callPackage ./neospleen.nix { };
  neospleen-nerdfont = pkgs.callPackage ./neospleen-nerdfont.nix { };
  mass-driver = pkgs.callPackage ./mass-driver.nix { };
in
{
  fonts = {
    packages = with pkgs; [
      neospleen
      neospleen-nerdfont
      mass-driver
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      spleen
    ];
  }
  // (
    if pkgs.stdenv.isDarwin then
      { }
    else
      {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
      }
  );
}
