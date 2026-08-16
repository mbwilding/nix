{ ... }:

{
  flake.modules.nixos.secrets = { ... }: {
    _module.args.secrets = import ../../../nix/_secrets.nix;
  };
}
