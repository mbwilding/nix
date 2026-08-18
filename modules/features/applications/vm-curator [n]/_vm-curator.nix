{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gcc,
  udev,
  testers,
}:

let
  version = "1.4.0";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/mroboff/vm-curator/releases/download/v${version}/vm-curator-v${version}-linux-x86_64.tar.gz";
      hash = "sha256-eD6U2ZICnFbrNA9P1DU2RB5EG7W9YHazJe73XkSjObc=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation (finalAttrs: {
  pname = "vm-curator";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    gcc.cc.lib
    udev
  ];

  strictDeps = true;
  __structuredAttrs = true;

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 vm-curator $out/bin/vm-curator
    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
  };

  meta = {
    description = "Fast and friendly TUI to build and manage QEMU/KVM virtual machines with working 3D acceleration";
    homepage = "https://github.com/mroboff/vm-curator";
    downloadPage = "https://github.com/mroboff/vm-curator/releases";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ mbwilding ];
    platforms = builtins.attrNames sources;
    mainProgram = "vm-curator";
  };
})
