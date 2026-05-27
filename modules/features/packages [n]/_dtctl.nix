{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.28.0";
  pname = "dtctl";
  repo = "https://github.com/dynatrace-oss/dtctl";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "${repo}/releases/download/v${version}/${pname}_${version}_linux_amd64.tar.gz";
    hash = "sha256-gVnFHtComldTQ8exaG9Mgx0re4YZ0uvZfolVRXKvYYM=";
  };

  dontUnpack = false;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 dtctl $out/bin/dtctl
    runHook postInstall
  '';

  meta = {
    description = "CLI for the Dynatrace platform";
    homepage = "${repo}";
    downloadPage = "${repo}/releases";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers.mbwilding ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
