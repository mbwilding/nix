{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/nvidia.nix

    # ../../modules/system/kde.nix
    ../../modules/system/hyprland.nix

    ../../modules/system/default.nix
    ../../modules/system/obs.nix
    ../../modules/system/steam.nix
    ../../modules/system/wireguard.nix
    ../../modules/system/wireshark.nix
  ];

  # hardware.cpu.amd.updateMicrocode = true;

  networking.hostName = "anon";

  environment = {
    sessionVariables = {
      WAYLANDDRV_PRIMARY_MONITOR = "HDMI-A-2";
    };
  };

  system.stateVersion = "25.11";
}
