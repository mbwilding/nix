{ ... }:

{
  flake.modules.nixOnDroid.droid =
    { pkgs, lib, ... }:
    {
      environment.packages = with pkgs; [
        git
        neovim
        curl
        wget
      ];

      environment.etcBackupExtension = ".bak";

      # Pin nix to 2.31.2 — versions >=2.31.3 break PTY on Android (nix-on-droid#495)
      nix.package = lib.mkForce pkgs.nixVersions.nix_2_30;

      nix.extraOptions = ''
        experimental-features = nix-command flakes
      '';

      system.stateVersion = "24.05";
    };
}
