{ ... }:

{
  flake.modules.homeManager.jetbrains =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      dotnet = config.custom.dotnet.sdk;
      rider = pkgs.symlinkJoin {
        name = "rider-wrapped";
        paths = [ pkgs.jetbrains.rider ];
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
        pkgs.jetbrains.datagrip
        rider
      ];
    };
}
