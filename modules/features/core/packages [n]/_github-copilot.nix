{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  version = "1.0.2";
  pname = "github-copilot";
  repo = "https://github.com/github/app";

  src = fetchurl {
    url = "${repo}/releases/download/v${version}/GitHub-Copilot-linux-x64.AppImage";
    hash = "sha256-IFUhSwvI/+bBEwf3iFd4+IHOgDCF/+DBmiHME6MrSLU=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -Dm444 "${appimageContents}/GitHub Copilot.desktop" -T $out/share/applications/${pname}.desktop
    install -Dm444 "${appimageContents}/usr/share/icons/hicolor/128x128/apps/github.png" \
      -T $out/share/icons/hicolor/128x128/apps/${pname}.png

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=github' 'Exec=${meta.mainProgram}' \
      --replace-fail 'Icon=github' 'Icon="${pname}"'

    wrapProgram $out/bin/${pname} \
      --set ELECTRON_OZONE_PLATFORM_HINT auto
  '';

  meta = {
    description = "GitHub Copilot desktop app";
    homepage = "https://github.com/github/app";
    downloadPage = "${repo}/releases";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.mbwilding ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
