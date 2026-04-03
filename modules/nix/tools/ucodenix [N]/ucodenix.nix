{
  inputs,
  ...
}:

{
  flake.modules.nixos.ucodenix = {
    imports = [
      inputs.ucodenix.nixosModules.default
    ];

    services.ucodenix.enable = true;
  };
}
