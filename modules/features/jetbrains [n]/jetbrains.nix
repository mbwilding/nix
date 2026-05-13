{ ... }:

{
  flake.modules.homeManager.jetbrains =
    { pkgsMaster, ... }:

    {
      home.packages = [
        (pkgsMaster.jetbrains.datagrip.override { forceWayland = true; })
        (pkgsMaster.jetbrains.rider.override { forceWayland = true; })
      ];
    };
}
