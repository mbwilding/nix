{ pkgs, ... }:

let
  # neospleen = pkgs.callPackage ./neospleen.nix { };
  neospleen-nerdfont = pkgs.callPackage ./neospleen-nerdfont.nix { };
in
{
  fonts = {
    packages = with pkgs; [
      # neospleen
      neospleen-nerdfont
      # jetbrains-mono
      nerd-fonts.jetbrains-mono
      # iosevka
      nerd-fonts.iosevka
      nerd-fonts.caskaydia-mono
      # spleen
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
