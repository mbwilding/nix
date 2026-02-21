{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/default.nix
    ../../modules/system/kde.nix
  ];

  networking.hostName = "vm";

  system.stateVersion = "25.11";
}
