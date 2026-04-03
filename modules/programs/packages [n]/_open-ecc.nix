{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "open-ecc";
  version = "0.0.6";

  src = fetchFromGitHub {
    owner = "mbwilding";
    repo = "open-ecc";
    tag = "v${version}";
    hash = "sha256-YkSIJgGczbBnRd+tdPOS+P9MtUOe2BPhoU4FOvOQwEA=";
  };

  cargoHash = "sha256-W/V1xiUFEyEXhCpDoQjUxO2MKOiL+dTKJHrzfKvZ/PM=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  env.OPENSSL_NO_VENDOR = 1;

  cargoBuildFlags = [ "--package" "open_ecc_cli" ];
  cargoTestFlags = [ "--package" "open_ecc_cli" ];

  meta = with lib; {
    description = "Unofficial Elgato Command Centre cross-platform CLI";
    homepage = "https://github.com/mbwilding/open-ecc";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ mbwilding ];
    mainProgram = "ecc";
  };
}
