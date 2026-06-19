{
  lib,
  stdenvNoCC,
  vscode-utils,
  makeWrapper,
  nodejs,
}:

let
  ext = vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "rogalmic";
      name = "bash-debug";
      version = "0.3.9";
      hash = "sha256-f8FUZCvz/PonqQP9RCNbyQLZPnN5Oce0Eezm/hD19Fg=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "vscode-bash-debug";
  version = "0.3.9";

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    makeWrapper ${nodejs}/bin/node $out/bin/vscode-bash-debug \
      --add-flags "${ext}/share/vscode/extensions/rogalmic.bash-debug/out/bashDebug.js"
  '';

  meta = with lib; {
    description = "A debugger extension for bash scripts (using bashdb)";
    homepage = "https://github.com/rogalmic/vscode-bash-debug";
    license = licenses.mit;
  };
}
