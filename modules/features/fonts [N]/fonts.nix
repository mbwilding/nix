{ ... }:

{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    let
      neospleen = pkgs.callPackage ./_neospleen.nix { };
      neospleen-nerdfont = pkgs.callPackage ./_neospleen-nerdfont.nix { };
      segoe-ui = pkgs.callPackage ./_segoe-ui.nix { };
      # neospleen-local = pkgs.callPackage ./_neospleen-local.nix { };
      # neospleen-nerdfont-local = pkgs.callPackage ./_neospleen-nerdfont-local.nix { };
    in
    {
      fonts = {
        packages = with pkgs; [
          corefonts
          vista-fonts
          segoe-ui
          neospleen
          neospleen-nerdfont
          # neospleen-local
          # neospleen-nerdfont-local
          nerd-fonts.jetbrains-mono
          nerd-fonts.iosevka
          nerd-fonts.caskaydia-mono
        ];

        fontDir.enable = true;
        enableGhostscriptFonts = true;
      };
    };
}
