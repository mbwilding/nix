{ pkgs, ... }:

{
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    steam-run
    steamtinkerlaunch
    vulkan-tools
  ];

  # Doing these in the Steam Tinker Launch global.conf
  # environment = {
  #   sessionVariables = {
  #     PROTON_ENABLE_HDR = 1;
  #     PROTON_ENABLE_WAYLAND = 1;
  #     PROTON_USE_NTSYNC = 1;
  #     DXVK_HDR = 1;
  #   };
  # };

  system.activationScripts.steamtinkerlaunch = {
    text = "steamtinkerlaunch compat add";
  };
}
