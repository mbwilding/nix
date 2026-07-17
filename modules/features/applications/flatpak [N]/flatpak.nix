{ inputs, ... }:

{
  flake.modules.nixos.flatpak = { };

  flake.modules.homeManager.flatpak = inputs.nix-flatpak.homeManagerModules.nix-flatpak;
}
