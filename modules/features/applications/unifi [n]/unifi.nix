{ inputs, ... }:

{
  flake.modules.homeManager.unifi =
    { pkgs, secrets, ... }:
    {
      home = {
        packages = [ inputs.unifi-cli.packages.${pkgs.stdenv.hostPlatform.system}.default ];

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
