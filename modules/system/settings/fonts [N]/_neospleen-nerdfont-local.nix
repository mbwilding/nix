{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "neospleen-nerdfont-local";
  version = "local";

  src = /home/anon/dev/personal/neospleen/fonts;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src/NeoSpleenNerdFont-Regular.ttf $out/share/fonts/truetype/
    cp $src/NeoSpleenNerdFont-Medium.ttf $out/share/fonts/truetype/
    cp $src/NeoSpleenNerdFont-Bold.ttf $out/share/fonts/truetype/
  '';

  meta = with lib; {
    homepage = "https://github.com/mbwilding";
    description = "NeoSpleen Nerd Font (local build)";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ mbwilding ];
  };
}
