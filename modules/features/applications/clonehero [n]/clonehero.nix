{ ... }:

{
  flake.modules.homeManager.clonehero =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    lib.mkIf (!work) {
      home.packages = [ pkgs.clonehero ];
    };
}
