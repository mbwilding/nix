{ ... }:

{
  flake.modules.homeManager.vm-curator =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.vm-curator
        pkgs.qemu
      ];
    };
}
