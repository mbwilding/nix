{ pkgs, ... }:

let
  actions-languageserver = pkgs.stdenv.mkDerivation {
    pname = "actions-languageserver";
    version = "0.3.49";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@actions/languageserver/-/languageserver-0.3.49.tgz";
      hash = "sha256-h3B8Qqn4dU2+aDyzGQqvWIsTU4dwO5Qznm4C0gWTXx4=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/lib/actions-languageserver $out/bin
      cp -r dist bin $out/lib/actions-languageserver/

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/gh-actions-language-server \
        --add-flags "$out/lib/actions-languageserver/bin/actions-languageserver"
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
  home.packages = [
    actions-languageserver
  ];
}
