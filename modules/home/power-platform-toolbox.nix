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
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  appimageContents = appimageTools.extractType1 {
    name = pname;
    src = src;
  };

in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${meta.mainProgram}'
  '';

  meta = {
    description = "Power Platform Toolbox";
    homepage = "https://www.powerplatformtoolbox.com";
    downloadPage = "${repo}/releases";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.mbwilding ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "Power-Platform-ToolBox";
  };
}
