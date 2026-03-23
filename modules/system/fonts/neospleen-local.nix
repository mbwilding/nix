{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "neospleen-local";
  version = "local";

  src = /home/anon/dev/personal/neospleen/fonts;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src/NeoSpleen-Regular.ttf $out/share/fonts/truetype/
    cp $src/NeoSpleen-Medium.ttf $out/share/fonts/truetype/
    cp $src/NeoSpleen-Bold.ttf $out/share/fonts/truetype/
  '';

  meta = with lib; {
    homepage = "https://github.com/mbwilding";
    description = "NeoSpleen (local build)";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ mbwilding ];
  };
}
