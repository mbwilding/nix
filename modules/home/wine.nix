{ lib, pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      wineWow64Packages.staging
      winetricks
    ];

    activation.winetricksCorefonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${pkgs.wineWow64Packages.staging}/bin/wine --version >/dev/null 2>&1; then
        echo "Wine not found: skipping winetricks corefonts"
        exit 0
      fi
      if ! ${pkgs.wineWow64Packages.staging}/bin/wine "C:\\Windows\\Fonts\\arial.ttf" >/dev/null 2>&1; then
        echo "Installing corefonts via winetricks..."
        ${pkgs.winetricks}/bin/winetricks corefonts
      else
        echo "Corefonts already installed"
      fi
    '';
  };
}
