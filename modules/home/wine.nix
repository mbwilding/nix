{ lib, pkgs, ... }:

let
  installs = [
    "corefonts"
    "dotnet20"
    "dotnet35"
    "dotnet40"
    "dotnet45"
    "dotnet452"
    "dotnet46"
    "dotnet461"
    "dotnet462"
    "dotnet47"
    "dotnet471"
    "dotnet472"
    "dotnet48"
  ];
in
{
  home = {
    packages = with pkgs; [
      wineWow64Packages.staging
      winetricks
    ];

    activation.winetricksCorefonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.wineWow64Packages.staging}/bin:$PATH"
      ${pkgs.winetricks}/bin/winetricks --country=AU --optout --unattended ${lib.concatStringsSep " " installs}
    '';
  };
}
