{ inputs, ... }:

let
  hostName = "droid";
  stateVersion = "24.05";
in
{
  flake.modules.nixOnDroid.${hostName} =
    { pkgs, ... }:
    {
      environment.packages = with pkgs; [
        curl
        git
        vim
        wget
      ];

      environment.etcBackupExtension = ".bak";
      system.stateVersion = stateVersion;

      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        config = inputs.self.modules.homeManager."user-${hostName}";
        extraSpecialArgs = {
          secrets = import ../../nix/_secrets.nix;
        };
      };
    };

  flake.nixOnDroidConfigurations = inputs.self.lib.mkNixOnDroid hostName;
}
