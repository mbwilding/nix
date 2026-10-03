{ inputs, ... }:

{
  flake.modules.homeManager.unifi =
    {
      config,
      lib,
      pkgs,
      secrets,
      ...
    }:
    let
      unifi = inputs.unifi-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
      completion =
        shell: dir: file:
        pkgs.runCommand "unifi-${shell}-completion" { } ''
          mkdir -p $out/${dir}
          ${unifi}/bin/unifi completions ${shell} > $out/${dir}/${file}
        '';
    in
    {
      home = {
        packages = [
          unifi
        ]
        ++ lib.optional config.programs.fish.enable (
          completion "fish" "share/fish/vendor_completions.d" "unifi.fish"
        )
        ++ lib.optional config.programs.zsh.enable (completion "zsh" "share/zsh/site-functions" "_unifi");

        file.".config/unifi/config.toml" = {
          force = true;
          source = (pkgs.formats.toml { }).generate "unifi-config.toml" {
            host = "https://unifi";
            api_key = secrets.unifiKey;
            accept_invalid_certs = true;
          };
        };
      };
    };
}
