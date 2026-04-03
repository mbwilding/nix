{
  inputs,
  ...
}:
{
  # CPU microcode updates via ucodenix
  # https://github.com/e-tho/ucodenix

  flake.modules.nixos.ucodenix = {
    imports = [
      inputs.ucodenix.nixosModules.default
    ];

    services.ucodenix.enable = true;
  };
}
