{ inputs, ... }:

{
  flake.modules.homeManager.affinity =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.affinity-v3
      ];
    };
}
