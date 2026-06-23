{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  pname = "github-copilot";
  version = "1.0.5";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-linux-x64.AppImage";
      hash = "sha256-u7TJHmAagbqgcO6zlDiubtxTM+LhuaTD+HWcrH12PKw=";
    };
    "aarch64-linux" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-linux-arm64.AppImage";
      hash = "sha256-70wFrWiYKIcIHQnn52fu0VEiwzDnCpszktF3ble6iaA=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-darwin-arm64.tar.gz";
      hash = "sha256-2UF5cRk4tKbKBu3rx+0FQs7/ebgJbfZVdLEebFcp/d4=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-darwin-x64.tar.gz";
      hash = "sha256-6qeU59TYcxosLkmYyZhTcSUUGJzBr9ut5+MRFaASS/E=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl { inherit (source) url hash; };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

  meta = {
    description = "GitHub Copilot desktop app";
    homepage = "https://github.com/github/app";
    downloadPage = "https://github.com/github/app/releases";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ mbwilding ];
    platforms = builtins.attrNames sources;
    mainProgram = pname;
  };

  linuxPkg =
    (appimageTools.wrapType2 {
      inherit pname version src;

      nativeBuildInputs = [ makeWrapper ];

      extraInstallCommands = ''
        install -Dm444 "${appimageContents}/GitHub Copilot.desktop" -T $out/share/applications/${pname}.desktop
        install -Dm444 "${appimageContents}/usr/share/icons/hicolor/128x128/apps/github.png" \
          -T $out/share/icons/hicolor/128x128/apps/${pname}.png

        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace-fail 'Exec=github' "Exec=${pname}" \
          --replace-fail 'Icon=github' "Icon=${pname}"

        wrapProgram $out/bin/${pname} \
          --set ELECTRON_OZONE_PLATFORM_HINT auto
      '';

      meta = meta;
    }).overrideAttrs
      {
        strictDeps = true;
        __structuredAttrs = true;
      };

  darwinPkg = stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [ makeWrapper ];

    strictDeps = true;
    __structuredAttrs = true;

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      cp -r "GitHub Copilot.app" "$out/Applications/GitHub Copilot.app"
      makeWrapper "$out/Applications/GitHub Copilot.app/Contents/MacOS/github" "$out/bin/${pname}"
      runHook postInstall
    '';

    meta = meta;
  };
in
if stdenv.hostPlatform.isLinux then linuxPkg else darwinPkg
