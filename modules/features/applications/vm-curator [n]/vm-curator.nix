{ ... }:

{
  flake.modules.homeManager.vm-curator =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.callPackage ./_vm-curator.nix { })
        pkgs.qemu
      ];
    };
}
