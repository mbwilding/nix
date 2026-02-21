{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "neospleen";
  version = "1.0.62";

  fontRegular = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Regular.ttf";
    sha256 = "4c4357ca7a9872f534a87581a33e8d471323599cecf310c11ffe5d2cc30d27ab";
  };

  fontMedium = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Medium.ttf";
    sha256 = "a6df2b37792ceb164a289a47cae8e74fc0bf8dc5962de6f340ee263be321aacf";
  };

  fontBold = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Bold.ttf";
    sha256 = "4c8c3855770230f081890b71204a9b48a2755a72e17b3e9084b9a014d2e2afc5";
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
