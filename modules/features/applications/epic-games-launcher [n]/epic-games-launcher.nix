{ inputs, ... }:

{
  flake.modules.homeManager.epic-games-launcher =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    lib.mkIf (!work) {
      home.packages = [
        inputs.epic-games-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
