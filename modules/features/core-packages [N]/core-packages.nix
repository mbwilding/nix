{ ... }:
{
  flake.modules.nixos.core-packages =
    { pkgs, ... }:
    let
      buildInputs = [
        "${pkgs.openssl.dev}/lib/pkgconfig"
        "${pkgs.wayland}/lib/pkgconfig"
        "${pkgs.wayland-protocols}/share/pkgconfig"
        "${pkgs.libxkbcommon}/lib/pkgconfig"
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
        };
        systemPackages = with pkgs; [
          cacert
          cifs-utils
          coreutils
          icu
          libva
          libva-utils
          libxkbcommon
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
