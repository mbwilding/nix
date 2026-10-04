{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "actions-languageserver";
  version = "0.3.61";

  src = fetchurl {
    url = "https://registry.npmjs.org/@actions/languageserver/-/languageserver-${finalAttrs.version}.tgz";
    hash = "sha512-L5Vf3zc3yD11xUSM8zMxrNwYLZpiUNG6U8kFK2BsxVyRKhU8gQEt02ydR+FZgidkrHSQO/2P7eU9vHPcOwwsOQ==";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 dist/cli.bundle.cjs $out/lib/actions-languageserver/cli.bundle.cjs
    makeWrapper ${lib.getExe nodejs} $out/bin/actions-languageserver \
      --add-flags $out/lib/actions-languageserver/cli.bundle.cjs
    runHook postInstall
  '';

  meta = {
    description = "Language server for GitHub Actions";
    homepage = "https://github.com/actions/languageservices";
    license = lib.licenses.mit;
    mainProgram = "actions-languageserver";
  };
})
