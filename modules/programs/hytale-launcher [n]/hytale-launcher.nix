{ ... }:

{
  flake.modules.homeManager.hytale-launcher =
    { pkgs, ... }:
    let
      runtimeDeps = with pkgs; [
        glib
        gtk3
        webkitgtk_4_1
        gdk-pixbuf
        libsoup_3
        cairo
        pango
        harfbuzz
        atk
        openssl
        zlib
        icu
        libGL
      ];

      hytale-launcher-fhs = pkgs.buildFHSEnv {
        name = "hytale-launcher";

        targetPkgs = pkgs: runtimeDeps ++ (with pkgs; [
          libxkbcommon
          mesa
          vulkan-loader
          alsa-lib
          pulseaudio
          dbus
          gsettings-desktop-schemas
          glib
          hicolor-icon-theme
          adwaita-icon-theme
          icu
          libGL
          curl
          unzip
          patchelf
        ]);

        profile = ''
          export GDK_BACKEND=wayland
          export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"
          # Keep TMPDIR on the same filesystem as the install dir so the launcher
          # can rename() patch archives without hitting a cross-device link error.
          export TMPDIR="$HOME/.local/share/Hytale/tmp"
          mkdir -p "$TMPDIR"
        '';

        runScript = pkgs.writeShellScript "hytale-launcher-wrapper" ''
          set -e

          LAUNCHER_DIR="$HOME/.local/share/hytale-launcher"
          LAUNCHER_BIN="$LAUNCHER_DIR/hytale-launcher"
          DOWNLOAD_URL="https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.zip"

          mkdir -p "$LAUNCHER_DIR"

          if [ ! -f "$LAUNCHER_BIN" ]; then
            echo "Downloading Hytale Launcher..."
            TEMP_DIR=$(mktemp -d)
            trap "rm -rf $TEMP_DIR" EXIT

            curl -L -o "$TEMP_DIR/launcher.zip" "$DOWNLOAD_URL"
            unzip -o "$TEMP_DIR/launcher.zip" -d "$TEMP_DIR"
            mv "$TEMP_DIR/hytale-launcher" "$LAUNCHER_BIN"
            chmod +x "$LAUNCHER_BIN"

            echo "Hytale Launcher installed successfully!"
          fi

          cd "$LAUNCHER_DIR"
          exec "$LAUNCHER_BIN" "$@"
        '';
      };

      desktopItem = pkgs.makeDesktopItem {
        name = "hytale-launcher";
        desktopName = "Hytale Launcher";
        comment = "Official Hytale Game Launcher";
        exec = "hytale-launcher";
        icon = "hytale-launcher";
        terminal = false;
        type = "Application";
        categories = [ "Game" ];
        keywords = [ "hytale" "game" "launcher" ];
      };

      hytaleIcon = pkgs.fetchurl {
        url = "https://hytale.com/images/logo-h.webp";
        hash = "sha256-VH5QsLTWl0TOj4aHwGYLonrJI27PlQkrnbTBNuzACWk=";
      };

      hytaleIconPng = pkgs.runCommand "hytale-launcher-icon" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } ''
        mkdir -p $out
        convert ${hytaleIcon} -thumbnail 256x256 -alpha on -background none -flatten $out/hytale-launcher.png
      '';

      hytale-launcher = pkgs.symlinkJoin {
        name = "hytale-launcher";
        paths = [ hytale-launcher-fhs desktopItem ];
        postBuild = ''
          mkdir -p $out/share/icons/hicolor/256x256/apps
          cp ${hytaleIconPng}/hytale-launcher.png $out/share/icons/hicolor/256x256/apps/hytale-launcher.png

          mkdir -p $out/share/pixmaps
          cp ${hytaleIconPng}/hytale-launcher.png $out/share/pixmaps/hytale-launcher.png
        '';

        meta = with pkgs.lib; {
          description = "Hytale Game Launcher";
          homepage = "https://hytale.com";
          license = licenses.unfree;
          platforms = [ "x86_64-linux" ];
          mainProgram = "hytale-launcher";
        };
      };
    in
    {
      home.packages = [ hytale-launcher ];
    };
}
