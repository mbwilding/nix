{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "neospleen-nerdfont";
  version = "1.0.62";

  fontRegular = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Regular.ttf";
    sha256 = "2588afcf2b460a611c9eed0dbf70207c8841170209cc0709152b9d274063fd53";
  };

  fontMedium = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Medium.ttf";
    sha256 = "f7f6792397d4d47e9337785468bf8d18380a0ddf6daa327728e34e8be021e008";
  };

  fontBold = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Bold.ttf";
    sha256 = "3c31ff43e12823355bd3758fc35b2631884dda6a6bcb0d60f51cfc7ca7512856";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $fontRegular $out/share/fonts/truetype/
    cp $fontMedium $out/share/fonts/truetype/
    cp $fontBold $out/share/fonts/truetype/
  '';

  meta = with lib; {
    homepage = "https://github.com/mbwilding";
    description = "NeoSpleen Nerd Font";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ mbwilding ];
  };
}
