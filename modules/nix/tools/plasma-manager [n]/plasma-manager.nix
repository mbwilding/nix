{
  inputs,
  ...
}:
{
  # Plasma Manager - declarative KDE Plasma configuration for Home Manager
  # https://github.com/nix-community/plasma-manager

  flake.modules.homeManager.plasma-manager = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };
}
