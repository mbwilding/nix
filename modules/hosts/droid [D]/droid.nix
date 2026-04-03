{ inputs, ... }:

{
  flake.modules.nixOnDroid.droid =
    { pkgs, ... }:
    {
      environment.packages = with pkgs; [
        git
        neovim
        curl
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
        config = inputs.self.modules.homeManager.droid;
        extraSpecialArgs = {
          secrets = import ../../nix/_secrets.nix;
          hostname = "droid";
        };
      };

      system.stateVersion = "24.05";
    };
}
