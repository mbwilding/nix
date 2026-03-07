{ pkgs, ... }:

let
  soundTheme = pkgs.sound-theme-freedesktop;
  volumeSound = "${soundTheme}/share/sounds/freedesktop/stereo/audio-volume-change.oga";

  config =
    pkgs.runCommand "quickshell-config"
      {
        inherit volumeSound;
      }
      ''
        mkdir -p $out
        # Copy root-level QML files
        cp ${./quickshell}/*.qml $out/
        # Recursively copy any subdirectories containing QML files
        for dir in ${./quickshell}/*/; do
          if [ -d "$dir" ]; then
            subdir=$(basename "$dir")
            mkdir -p "$out/$subdir"
            cp "$dir"*.qml "$out/$subdir/" 2>/dev/null || true
          fi
        done
        substituteInPlace $out/Sounds.qml \
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

  xdg.dataFile = builtins.listToAttrs (
    map
      (size: {
        name = "icons/hicolor/${size}x${size}/apps/spotify.png";
        value.source = "${pkgs.spotify}/share/icons/hicolor/${size}x${size}/apps/spotify-client.png";
      })
      [
        "16"
        "22"
        "24"
        "32"
        "48"
        "64"
        "128"
        "256"
        "512"
      ]
  );

  home = {
    packages = with pkgs; [
      coreutils
      libnotify
    ];

    file."nix/modules/home/quickshell/.qmlls.ini".source = qmllsIni;
  };
}
