{ inputs, ... }:

{
  flake.modules.nixos.flatpak = {
    home-manager.sharedModules = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      {
        # NOTE: Example
        # services.flatpak.packages = [
        #   {
        #     appId = "com.hytale.Hytale";
        #     origin = "flathub";
        #   }
        # ];
      }
    ];
  };
}
