{ ... }:

{
  flake.modules.homeManager.jetbrains =
    {
      lib,
      pkgs,
      pkgsMaster,
      config,
      ...
    }:

    let
      dotnet = config.custom.dotnet.sdk;
      riderPkg = pkgsMaster.jetbrains.rider.override { forceWayland = true; };
      rider = pkgs.symlinkJoin {
        name = "rider-wrapped";
        paths = [ riderPkg ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/rider/bin/rider \
            --set DOTNET_ROOT "${dotnet}/share/dotnet" \
            --prefix PATH : "${
              lib.makeBinPath [
                dotnet
                pkgs.mono
                pkgs.msbuild
              ]
            }"
        '';
      };
    in
    {
      home.packages = [
        (pkgsMaster.jetbrains.datagrip.override { forceWayland = true; })
        rider
      ];
    };
}
