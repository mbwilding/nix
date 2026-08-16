{ inputs, ... }:

{
  flake.modules.nixos.flatpak =
    { ... }:
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      services.flatpak.enable = true;
    };

  flake.modules.homeManager.flatpak = inputs.nix-flatpak.homeManagerModules.nix-flatpak;
}
