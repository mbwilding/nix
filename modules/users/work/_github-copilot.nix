{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  pname = "github-copilot";
  version = "1.1.23";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-linux-x64.AppImage";
      hash = "sha256-5b8phGCPnOnMO3Uh/sbg2RzmHXU7pzYvUZ5evE6zWZk=";
    };
    "aarch64-linux" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-linux-arm64.AppImage";
      hash = "sha256-nPgbmOzj9bYzNM1Rlf7Ah8nIBESTfvIpcJzPC07RqwM=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-darwin-arm64.tar.gz";
      hash = "sha256-PHs8YWfE6X7dn4Lc3ESNgaViIpyELjA0Bnrqp/UrP8s=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/github/app/releases/download/v${version}/GitHub-Copilot-darwin-x64.tar.gz";
      hash = "sha256-F7BsitEkCMTTDh9555EgMPrMSdWBTtFwDhIL1pOzOXI=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl { inherit (source) url hash; };

  appimageContents = appimageTools.extract {
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
