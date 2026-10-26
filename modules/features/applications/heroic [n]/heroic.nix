{ ... }:

{
  flake.modules.homeManager.heroic =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    lib.mkIf (!work) {
      home.packages = [ pkgs.heroic ];
    };
}
