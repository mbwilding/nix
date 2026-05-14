{ ... }:
{
  flake.modules.nixos.core-programs =
    { pkgs, ... }:
    {
      programs = {
        fish.enable = true;
        mtr.enable = true;
        nano.enable = false;
        _1password.enable = true;
        nix-ld = {
          enable = true;
          libraries = with pkgs; [
            icu
            # Unreal Engine runtime dependencies
            stdenv.cc.cc.lib # libstdc++.so.6
            glib # libglib-2.0, libgobject-2.0, libgio-2.0
            nss # libnss3, libnssutil3, libsmime3
            nspr # libnspr4
            dbus # libdbus-1
            at-spi2-atk # libatk-bridge-2.0
            atk # libatk-1.0, libatspi
            libdrm # libdrm
            libx11 # libX11
            libxcomposite # libXcomposite
            libxdamage # libXdamage
            libxext # libXext
            libxfixes # libXfixes
            libxrandr # libXrandr
            mesa # libgbm
            expat # libexpat
            libxcb # libxcb
            libxkbcommon # libxkbcommon
            pango # libpango-1.0
            cairo # libcairo
            alsa-lib # libasound
          ];
        };
      };
    };
}
