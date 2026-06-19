{ ... }:

{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    let
      neospleen = pkgs.callPackage ./_neospleen.nix { };
      neospleen-nerdfont = pkgs.callPackage ./_neospleen-nerdfont.nix { };
      microsoft-fonts = pkgs.callPackage ./_microsoft-fonts.nix { };
      # neospleen-local = pkgs.callPackage ./_neospleen-local.nix { };
      # neospleen-nerdfont-local = pkgs.callPackage ./_neospleen-nerdfont-local.nix { };
    in
    {
      fonts = {
        packages = with pkgs; [
          neospleen
          neospleen-nerdfont
          microsoft-fonts

          libre-baskerville
          nerd-fonts.jetbrains-mono
          nerd-fonts.iosevka
          nerd-fonts.caskaydia-mono
        ];

        fontDir.enable = true;
        enableGhostscriptFonts = true;
      };
    };
}
