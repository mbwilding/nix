{ lib, pkgs, ... }:

let
  installs = [
    "corefonts"
    "dotnet35"
    "dotnet35sp1"
    "dotnet40"
    "dotnet45"
    "dotnet46"
    "dotnet461"
    "dotnet462"
    "dotnet471"
    "dotnet472"
    "dotnet48"
    "powershell"
    "powershell_core"
    "vcrun2005"
    "vcrun2008"
    "vcrun2010"
    "vcrun2012"
    "vcrun2013"
    "vcrun2015"
    "vcrun2017"
    "vcrun2019"
    "vcrun2022"
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
