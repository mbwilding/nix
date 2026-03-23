{ pkgs, ... }:

let
  neospleen = pkgs.callPackage ./neospleen.nix { };
  neospleen-nerdfont = pkgs.callPackage ./neospleen-nerdfont.nix { };
  neospleen-local = pkgs.callPackage ./neospleen-local.nix { };
  neospleen-nerdfont-local = pkgs.callPackage ./neospleen-nerdfont-local.nix { };
in
{
  fonts = {
    packages = with pkgs; [
      neospleen
      neospleen-nerdfont
      # neospleen-local
      # neospleen-nerdfont-local
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
