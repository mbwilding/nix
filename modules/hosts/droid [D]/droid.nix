{ inputs, ... }:

let
  hostName = "droid";
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

      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        config = inputs.self.modules.homeManager."user-${hostName}";
        extraSpecialArgs = {
          secrets = import ../../nix/_secrets.nix;
        };
      };

      system.stateVersion = "24.05";
    };

  flake.nixOnDroidConfigurations = inputs.self.lib.mkNixOnDroid hostName;
}
