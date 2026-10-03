{
  lib,
  stdenvNoCC,
  makeWrapper,
  nodejs,
  bash-debug,
}:

stdenvNoCC.mkDerivation {
  pname = "vscode-bash-debug";
  inherit (bash-debug) version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    makeWrapper ${nodejs}/bin/node $out/bin/vscode-bash-debug \
      --add-flags "${bash-debug}/share/vscode/extensions/rogalmic.bash-debug/out/bashDebug.js"
  '';

  meta = with lib; {
    description = "A debugger extension for bash scripts (using bashdb)";
    homepage = "https://github.com/rogalmic/vscode-bash-debug";
    license = licenses.mit;
  };
}
