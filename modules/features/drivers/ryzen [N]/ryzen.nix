{ ... }:

{
  flake.modules.nixos.ryzen =
    { config, ... }:
    {
      boot = {
        extraModulePackages = [ config.boot.kernelPackages.ryzen-smu ];
        kernelModules = [
          "ryzen_smu"
          "spd5118"
        ];
      };
    };
}
