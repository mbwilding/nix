{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  pname = "vela-cli";
  version = "0.0.33";

  # Vela is Open Design's proprietary AMR (image/video generation) backend,
  # distributed as a closed-source binary via npm. Open Design's own release
  # pipeline only auto-bundles it into the packaged mac-arm64 beta build; on
  # every other platform (including Linux) the app skips bundling and expects
  # VELA_BIN / OPEN_DESIGN_VELA_CLI_BIN to point at it, or falls back to
  # reporting "vela binary not found". This derivation fetches the npm-hosted
  # Linux native package directly. See docs/plans/amr-vela-cli-ci-integration.md
  # in nexu-io/open-design for the resolution contract.
  sources = {
    "x86_64-linux" = {
      url = "https://registry.npmjs.org/@powerformer/vela-cli-linux-x64/-/vela-cli-linux-x64-${version}.tgz";
      hash = "sha256-E2sKhJO6PhUpFka/5GFwd/0y3DV2DORqCFYv/L//vi0=";
    };
    "aarch64-linux" = {
      url = "https://registry.npmjs.org/@powerformer/vela-cli-linux-arm64/-/vela-cli-linux-arm64-${version}.tgz";
      hash = "sha256-N06jHJ1fbh01GChJlS5CQ8Xp3RvteiZrBr64pGqbKaU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl { inherit (source) url hash; };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = "package";

  installPhase = ''
    runHook preInstall

    # Preserve the bin/libexec/opencode/opencode relative layout: vela
    # resolves its bundled OpenCode companion beside its own binary path.
    mkdir -p $out
    cp -r bin $out/bin
    chmod +x $out/bin/vela $out/bin/libexec/opencode/opencode

    runHook postInstall
  '';

  meta = {
    description = "Vela CLI — proprietary AMR backend for Open Design's image/video generation";
    homepage = "https://open-design.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ mbwilding ];
    platforms = builtins.attrNames sources;
    mainProgram = "vela";
  };
}
