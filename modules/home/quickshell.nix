{ pkgs, ... }:

let
  pamDir = pkgs.writeTextDir "pam/password.conf" ''
    auth include login
  '';

  shellQml = pkgs.replaceVars ./quickshell/shell.qml {
    pamDir = "${pamDir}/pam";
  };

  config = pkgs.runCommand "quickshell-config" { } ''
    mkdir -p $out
    cp ${shellQml} $out/shell.qml
    cp ${./quickshell/osd.qml} $out/osd.qml
  '';

  qmlImportPaths = [
    "${pkgs.quickshell}/lib/qt-6/qml"
    "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
  ];

  qmllsIni = pkgs.writeText "qmlls.ini" ''
    [General]
    DisableDefaultImports=false
    no-cmake-calls=false
    importPaths=${builtins.concatStringsSep "," qmlImportPaths}
  '';
in
{
  programs.quickshell = {
    enable = true;
    configs.default = config;
    activeConfig = "default";
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };

  home.file."nix/modules/home/quickshell/.qmlls.ini".source = qmllsIni;
}
