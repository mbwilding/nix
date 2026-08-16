{ lib, pkgs }:

pkgs.buildNpmPackage {
  pname = "gh-actions-language-server";
  version = "0.0.3";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-0.0.3.tgz";
    hash = "sha512-T2ph7OoS0tnpWsxpvdiC5k9rrv5t7BMwZRJANrk4gZzvTZ1/rY1kpJQjVaiYeTrlj2fDgQh5fMwPqkxNaKIGdw==";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./gh-actions-language-server-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-tefbD/2BdyqajOQ3jdl/5ljBtUGORXOxOt9HqWKZ4pA=";
  npmFlags = [ "--omit=dev" ];
  dontNpmBuild = true;

  meta = {
    description = "Language server for GitHub Actions";
    homepage = "https://github.com/actions/languageservices";
    license = lib.licenses.mit;
    mainProgram = "gh-actions-language-server";
  };
}
