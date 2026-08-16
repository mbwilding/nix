{ ... }:

{
  flake.modules.homeManager.teams =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        teams-for-linux
        libfido2
      ];

      home.file.".config/teams-for-linux/config.json".text = builtins.toJSON {
        auth = {
          webauthn = {
            enabled = true;
          };
        };
      };
    };
}
