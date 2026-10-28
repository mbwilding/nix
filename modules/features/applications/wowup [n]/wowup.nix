{ ... }:

{
  flake.modules.homeManager.wowup =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    lib.mkIf (!work) {
      home.packages = [ pkgs.wowup-cf ];
    };
}
