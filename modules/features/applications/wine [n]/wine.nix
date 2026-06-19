{ ... }:

{
  flake.modules.nixos.wine =
    { ... }:
    {
      boot.kernelModules = [ "ntsync" ];
    };

  flake.modules.homeManager.wine =
    { pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
          wineWow64Packages.staging
          winetricks
        ];
      };
    };
}
