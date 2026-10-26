{ inputs, ... }:

{
  flake.modules.homeManager.steam-achievement-manager =
    {
      pkgs,
      lib,
      work,
      ...
    }:
    lib.mkIf (!work) {
      home.packages = [
        inputs.steam-achievement-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
