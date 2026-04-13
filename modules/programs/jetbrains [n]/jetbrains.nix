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

      rider =
        (pkgsMaster.jetbrains.rider.override {
          forceWayland = true;
        }).overrideAttrs
          (old: {
            postInstall =
              (old.postInstall or "")
              + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                for dir in $out/rider/lib/ReSharperHost/linux-*; do
                  rm -rf $dir/dotnet
                  ln -s ${dotnet}/share/dotnet $dir/dotnet
                done
              '';
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/rider/bin/rider \
                --prefix PATH : "${
                  lib.makeBinPath [
                    dotnet
                    pkgs.mono
                    pkgs.msbuild
                  ]
                }"
            '';
          });
    in
    {
      home.packages = [
        (pkgsMaster.jetbrains.datagrip.override { forceWayland = true; })
        rider
      ];
    };
}
