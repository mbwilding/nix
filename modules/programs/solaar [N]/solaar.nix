{ inputs, ... }:

{
  flake.modules.nixos.solaar =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          solaar = prev.solaar.overrideAttrs (_: {
            src = inputs.solaar;
          });
        })
      ];

      environment.systemPackages = [ pkgs.solaar ];

      hardware.logitech.wireless.enable = true;
    };
}
