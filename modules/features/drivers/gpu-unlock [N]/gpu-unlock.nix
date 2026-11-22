{ inputs, ... }:

{
  flake.modules.nixos.gpu-unlock = {
    imports = [ inputs.gpu-unlock.nixosModules.default ];
  };
}
