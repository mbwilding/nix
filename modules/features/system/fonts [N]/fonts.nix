{ inputs, ... }:

{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    let
      inherit (inputs.neospleen.packages.${pkgs.stdenv.hostPlatform.system}) neospleen neospleen-nerdfont;
      microsoft-fonts = pkgs.callPackage ./_microsoft-fonts.nix { };
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
