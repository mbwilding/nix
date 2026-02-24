{ pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.dotnet_8.sdk
    pkgs.dotnetCorePackages.dotnet_9.sdk
    pkgs.dotnetCorePackages.dotnet_10.sdk
  ];
in
{
  environment = {
    systemPackages = [ dotnet ];

    sessionVariables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_ROOT = "${dotnet}/share/dotnet";
    };
  };
}
