{ pkgs, ... }:

let
  soundTheme = pkgs.sound-theme-freedesktop;
  notificationSound = "${soundTheme}/share/sounds/freedesktop/stereo/message-new-instant.oga";
  volumeSound = "${soundTheme}/share/sounds/freedesktop/stereo/audio-volume-change.oga";

  config =
    pkgs.runCommand "quickshell-config"
      {
        inherit notificationSound volumeSound;
      }
      ''
        mkdir -p $out
        cp ${./quickshell}/*.qml $out/
        substituteInPlace $out/Sounds.qml \
          --subst-var notificationSound \
          --subst-var volumeSound
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

  home = {
    packages = with pkgs; [
      libnotify
    ];

    file."nix/modules/home/quickshell/.qmlls.ini".source = qmllsIni;
  };
}
