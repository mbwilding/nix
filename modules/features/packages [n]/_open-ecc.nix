{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.0.7";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/mbwilding/open-ecc/releases/download/v${version}/ecc-Linux-musl-x86_64.tar.gz";
      hash = "sha256-NaSVQ8WcbN2PEpNuaz/JEex/1T5mHgz7vQWsAdPR2gc=";
    };
    "aarch64-linux" = {
      url = "https://github.com/mbwilding/open-ecc/releases/download/v${version}/ecc-Linux-musl-arm64.tar.gz";
      hash = "sha256-cRrBWgY25owmtyCaNc8wXyhfshYhsbc8vgInuw/klJE=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/mbwilding/open-ecc/releases/download/v${version}/ecc-macOS-arm64.tar.gz";
      hash = "sha256-sepO2Ws6qfQqEqGootKoqLF9TjB2sfDhgBaiQ6Rpcm4=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/mbwilding/open-ecc/releases/download/v${version}/ecc-macOS-x86_64.tar.gz";
      hash = "sha256-I33KRaVTUKaYJG5zqjFMArLW5gqcVTOZU/QaOxJtMeA=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation {
  pname = "open-ecc";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 ecc $out/bin/ecc
  '';

  meta = with lib; {
    description = "Unofficial Elgato Command Centre cross-platform CLI";
    homepage = "https://github.com/mbwilding/open-ecc";
    license = licenses.mit;
    platforms = builtins.attrNames sources;
    maintainers = with maintainers; [ mbwilding ];
    mainProgram = "ecc";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
