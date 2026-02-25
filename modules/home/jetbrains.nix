{ lib, pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.dotnet_9.sdk
  ];

  # Wrap Rider so it inherits DOTNET_ROOT, mono, and msbuild at launch,
  # regardless of whether the session variables have been sourced by a shell.
  rider = pkgs.symlinkJoin {
    name = "rider-with-dotnet";
    paths = [ pkgs.jetbrains.rider ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/rider \
        --prefix PATH : "${lib.makeBinPath [ dotnet pkgs.msbuild pkgs.mono ]}" \
        --set DOTNET_ROOT "${dotnet}/share/dotnet" \
        --set DOTNET_HOST_PATH "${dotnet}/share/dotnet/dotnet" \
        --set MSBuildSDKsPath "${dotnet}/share/dotnet/sdk/${pkgs.dotnetCorePackages.dotnet_9.sdk.version}/Sdks" \
        --set MSBUILD_EXE_PATH "${pkgs.msbuild}/lib/mono/msbuild/Current/bin/MSBuild.dll" \
        --set MONO_GAC_PREFIX "${pkgs.mono}" \
        --set-default DOTNET_CLI_TELEMETRY_OPTOUT "1"
    '';
  };
in
{
  home.packages = with pkgs; [
    jetbrains.datagrip
    mono
    rider
  ];
}
