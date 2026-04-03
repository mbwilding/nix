{
  inputs,
  ...
}:
{
  # Core setup for the Dendritic Pattern:
  #   flake-parts  - module system for flakes
  #   import-tree  - auto-import all .nix files under ./modules

  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  systems = [
    "x86_64-linux"
  ];
}
