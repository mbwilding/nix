{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "neospleen";
  version = "1.1.63";

  fontRegular = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Regular.ttf";
    sha256 = "ba139384344d608931c09fb86ec45abeb28a04bf952bec2eaa503192f160e894";
  };

  fontMedium = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Medium.ttf";
    sha256 = "2b7e15a91d1c349fc94111231fb8e96e2647a43dad8b08049aa1df988e8f1ba2";
  };

  fontBold = fetchurl {
    url = "https://github.com/mbwilding/NeoSpleen/releases/download/${version}/NeoSpleen-Bold.ttf";
    sha256 = "904fcac1cc28c13459a0968dc31e70d4dccc1f1cb1c25db8df1d25f3e7877ca4";
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
