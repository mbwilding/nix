{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
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

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = false;
  dontBuild = true;
  dontConfigure = true;

  sourceRoot = ".";

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
