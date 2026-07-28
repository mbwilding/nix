{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  testers,
}:

let
  version = "0.35.0";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/dynatrace-oss/dtctl/releases/download/v${version}/dtctl_${version}_linux_amd64.tar.gz";
      hash = "sha256-zSDLuW66I8455IntCzdNeHnbiv9SbbEQXwFl52zg8lQ=";
    };
    "aarch64-linux" = {
      url = "https://github.com/dynatrace-oss/dtctl/releases/download/v${version}/dtctl_${version}_linux_arm64.tar.gz";
      hash = "sha256-IeirPsc0dGqusZpD7m90ZaaAiRRPGdgUl/7i61YPslk=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/dynatrace-oss/dtctl/releases/download/v${version}/dtctl_${version}_darwin_amd64.tar.gz";
      hash = "sha256-pKFocV09PTV1jNx3NbQr2xEefUGQtishl8ZRuIDpt/Q=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/dynatrace-oss/dtctl/releases/download/v${version}/dtctl_${version}_darwin_arm64.tar.gz";
      hash = "sha256-SLPIgRhdlIzV5qNdizekCsYhpTapy4TZLqq3/9WV6JU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation (finalAttrs: {
  pname = "dtctl";
  version = version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = [ makeWrapper ];

  sourceRoot = ".";

  strictDeps = true;
  __structuredAttrs = true;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 dtctl $out/bin/dtctl
    wrapProgram $out/bin/dtctl \
      --set DTCTL_TOKEN_STORAGE file
    install -Dm644 completions/dtctl.bash $out/share/bash-completion/completions/dtctl
    install -Dm644 completions/dtctl.fish $out/share/fish/vendor_completions.d/dtctl.fish
    install -Dm644 completions/dtctl.zsh $out/share/zsh/site-functions/_dtctl
    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "dtctl version";
  };

  meta = {
    description = "CLI for the Dynatrace platform";
    homepage = "https://github.com/dynatrace-oss/dtctl";
    downloadPage = "https://github.com/dynatrace-oss/dtctl/releases";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ mbwilding ];
    platforms = builtins.attrNames sources;
    mainProgram = "dtctl";
  };
})
