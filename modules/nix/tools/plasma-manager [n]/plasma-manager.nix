{
  inputs,
  ...
}:

{
  flake.modules.homeManager.plasma-manager = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };
}
