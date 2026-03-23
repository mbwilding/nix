{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "neospleen-nerdfont";
  version = "1.1.63";

  fontRegular = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Regular.ttf";
    sha256 = "64d41d00198251f4e2e3efd3fadb6098a618c6660d0e6cd3df554fb2f85366fc";
  };

  fontMedium = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Medium.ttf";
    sha256 = "8cc4b08d4aa1b40c9d3880ea9928c39aea041420ac471326111ded56b42b0b3d";
  };

  fontBold = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleenNerdFont-Bold.ttf";
    sha256 = "ea59553550ec3e605e764b2cbed2c6fcb403bb88fa5f120de5015fc9ea05b089";
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
