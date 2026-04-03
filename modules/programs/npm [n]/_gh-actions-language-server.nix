{ pkgs, ... }:

let
  npmDepsHashes = {
    "x86_64-linux" = "sha256-wh6oE5sRuZ8vJjmU5Tk37rvliibszLpxnzU7n+p5eAw=";
    "aarch64-linux" = "sha256-IJXY12+x/HegeM4MfMRpTOYzCpRJ3eDXyywOLFqc9WY=";
  };

  gh-actions-language-server = pkgs.buildNpmPackage {
    pname = "gh-actions-language-server";
    version = "0.0.3";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-0.0.3.tgz";
      hash = "sha256-lgisfGIWGT/WCGqOfm/rqSXVeDWqSge2YJ+ZiBMmS48=";
    };

    sourceRoot = "package";

    postPatch = ''
      cp ${./gh-actions-language-server-lock.json} package-lock.json
    '';

    npmDepsFetcherVersion = 2;
    npmDepsHash = npmDepsHashes.${pkgs.stdenv.hostPlatform.system};
    npmFlags = [ "--omit=dev" ];
    dontNpmBuild = true;

    meta = {
      description = "Language server for GitHub Actions";
      homepage = "https://github.com/actions/languageservices";
      license = pkgs.lib.licenses.mit;
      mainProgram = "gh-actions-language-server";
    };
  };
in
{
  home.packages = [ gh-actions-language-server ];
}
