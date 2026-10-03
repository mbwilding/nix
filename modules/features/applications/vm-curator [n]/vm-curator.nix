{ inputs, ... }:

{
  flake.modules.homeManager.vm-curator =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.vm-curator.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.qemu
      ];
    };
}
