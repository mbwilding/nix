{ pkgs, ... }:

let
  gh-actions-language-server = pkgs.stdenv.mkDerivation {
    pname = "gh-actions-language-server";
    version = "0.0.3";

    # To update: nix-prefetch-url --type sha256 https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-<version>.tgz
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/gh-actions-language-server/-/gh-actions-language-server-0.0.3.tgz";
      hash = "sha256-lgisfGIWGT/WCGqOfm/rqSXVeDWqSge2YJ+ZiBMmS48=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/gh-actions-language-server $out/bin
      cp -r bin index.js $out/lib/gh-actions-language-server/

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gh-actions-language-server \
        --add-flags "$out/lib/gh-actions-language-server/bin/gh-actions-language-server"
    '';

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
