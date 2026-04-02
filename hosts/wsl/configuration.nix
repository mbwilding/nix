{ ... }:

{
  imports = [
    # ../../modules/system/default.nix
  ];

  networking.hostName = "wsl";

  system.stateVersion = "25.05";
}
