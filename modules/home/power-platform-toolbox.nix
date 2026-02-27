{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "1.1.3";
  pname = "power-platform-toolbox";
  repo = "https://github.com/PowerPlatformToolBox/desktop-app";

  src = fetchurl {
    url = "${repo}/releases/download/v${version}/Power-Platform-ToolBox-${version}-x86_64-linux.AppImage";
    hash = "sha256-9R51X7Ar3JqjMxhpSxatL20grURahPTn+V/yAmPiuMQ=";
  };

  appimageContents = appimageTools.extractType1 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/powerplatform-toolbox.desktop -T $out/share/applications/${pname}.desktop
    install -Dm444 ${appimageContents}/powerplatform-toolbox.png -T $out/share/icons/hicolor/512x512/apps/${pname}.png

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${meta.mainProgram}' \
      --replace-fail 'Icon=powerplatform-toolbox' 'Icon=${pname}'
  '';

  meta = {
    description = "Power Platform Toolbox";
    homepage = "https://www.powerplatformtoolbox.com";
    downloadPage = "${repo}/releases";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.mbwilding ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
