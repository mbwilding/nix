{ stdenv, ... }:

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.${stdenv.hostPlatform.system};
    in
    {
      devShells.${stdenv.hostPlatform.system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          pkg-config
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
        ];

        buildInputs = with pkgs; [
          openssl
          wayland
          wayland-protocols
          libxkbcommon
        ];
      };
    };
}
