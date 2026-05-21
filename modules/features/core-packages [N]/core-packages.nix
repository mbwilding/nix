{ ... }:
{
  flake.modules.nixos.core-packages =
    { pkgs, ... }:
    let
      buildInputs = [
        "${pkgs.fontconfig.dev}/lib/pkgconfig"
        "${pkgs.libGL.dev}/lib/pkgconfig"
        "${pkgs.libx11.dev}/lib/pkgconfig"
        "${pkgs.libxcursor}/lib/pkgconfig"
        "${pkgs.libxext.dev}/lib/pkgconfig"
        "${pkgs.libxi.dev}/lib/pkgconfig"
        "${pkgs.libxinerama.dev}/lib/pkgconfig"
        "${pkgs.libxkbcommon}/lib/pkgconfig"
        "${pkgs.libxrandr.dev}/lib/pkgconfig"
        "${pkgs.libxrender.dev}/lib/pkgconfig"
        "${pkgs.openssl.dev}/lib/pkgconfig"
        "${pkgs.wayland}/lib/pkgconfig"
        "${pkgs.wayland-protocols}/share/pkgconfig"
      ];
      runtimeLibs = [
        "${pkgs.fontconfig.lib}/lib"
        "${pkgs.libGL}/lib"
        "${pkgs.libICE}/lib"
        "${pkgs.libSM}/lib"
        "${pkgs.libx11}/lib"
        "${pkgs.libxcursor}/lib"
        "${pkgs.libxext}/lib"
        "${pkgs.libxi}/lib"
        "${pkgs.libxinerama}/lib"
        "${pkgs.libxkbcommon}/lib"
        "${pkgs.libxrandr}/lib"
        "${pkgs.libxrender}/lib"
        "${pkgs.libxshmfence}/lib"
      ];
    in
    {
      nixpkgs.config.allowUnfree = true;

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "wayland";
          NIXPKGS_ALLOW_UNFREE = 1;
          PKG_CONFIG_PATH = builtins.concatStringsSep ":" buildInputs;
          LD_LIBRARY_PATH = builtins.concatStringsSep ":" runtimeLibs;
        };
        systemPackages = with pkgs; [
          cacert
          cifs-utils
          coreutils
          fontconfig
          icu
          libGL
          libICE
          libSM
          libva
          libva-utils
          libx11
          libxcursor
          libxext
          libxi
          libxinerama
          libxkbcommon
          libxrandr
          libxrender
          libxshmfence
          openssl
          openssl.dev
          pkg-config
          skia
          wayland
          wayland-protocols
        ];
      };
    };
}
