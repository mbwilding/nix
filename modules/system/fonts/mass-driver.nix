{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "mass-driver-trial";
  version = "1.0";

  src = builtins.path {
    name = "mass-driver-trial-fonts";
    path = "/home/anon/Fonts/Mass-Driver Trial Fonts/Fonts";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/opentype

    cp "$src/MD IO/OTF/"*.otf                $out/share/fonts/opentype/
    cp "$src/MD Lórien/OTF/"*.otf            $out/share/fonts/opentype/
    cp "$src/MD Nichrome/OTF/"*.otf          $out/share/fonts/opentype/
    cp "$src/MD Polychrome/OTF/"*.otf        $out/share/fonts/opentype/
    cp "$src/MD Primer/OTF/"*.otf            $out/share/fonts/opentype/
    cp "$src/MD System/OTF/"*.otf            $out/share/fonts/opentype/
    cp "$src/MD System Condensed/OTF/"*.otf  $out/share/fonts/opentype/
    cp "$src/MD System Mono/OTF/"*.otf       $out/share/fonts/opentype/
    cp "$src/MD System Narrow/OTF/"*.otf     $out/share/fonts/opentype/
  '';

  meta = with lib; {
    description = "Mass-Driver Trial Fonts";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
