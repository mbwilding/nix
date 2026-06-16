{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  gcc,
}:

let
  version = "2.0.3";

  sources = {
    "x86_64-linux" = {
      url = "https://github.com/mbwilding/steam-achievement-manager/releases/download/v${version}/sam-linux-x64.zip";
      hash = "sha256-9550vfHLrsPRKCRHOdnl3+AtjDVAMMUxWrcT/6f6vyk=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/mbwilding/steam-achievement-manager/releases/download/v${version}/sam-mac-arm64.zip";
      hash = "sha256-mBGib35CqQB0EiCU2pK8rSGHEpoXTHQCWj5uQ4eSaUo=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/mbwilding/steam-achievement-manager/releases/download/v${version}/sam-mac-x64.zip";
      hash = "sha256-styxsf4GJWRSkLGkud2hvz0UX81A/IA05v+3GJo9iDo=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation {
  pname = "steam-achievement-manager";
  inherit version;

  src = fetchzip {
    inherit (source) url hash;
    stripRoot = false;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ gcc.cc.lib ];

  installPhase = ''
    install -Dm755 sam $out/bin/sam
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      install -Dm644 libsteam_api.so $out/lib/libsteam_api.so
    ''}
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      install -Dm644 libsteam_api.dylib $out/lib/libsteam_api.dylib
    ''}
  '';

  meta = with lib; {
    description = "Steam Achievement Manager CLI";
    homepage = "https://github.com/mbwilding/steam-achievement-manager";
    license = licenses.mit;
    platforms = builtins.attrNames sources;
    maintainers = with maintainers; [ mbwilding ];
    mainProgram = "sam";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
