{ ... }:

{
  flake.modules.nixos.droid =
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

      system.stateVersion = "24.05";
    };
}
