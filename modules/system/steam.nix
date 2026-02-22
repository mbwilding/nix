{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  environment.systemPackages = with pkgs; [
    gamemode
    # gamescope
    steam-run
    vulkan-tools
  ];

  environment = {
    sessionVariables = {
      PROTON_ENABLE_HDR = 1;
      PROTON_ENABLE_WAYLAND = 1;
      PROTON_USE_NTSYNC = 1;
      DXVK_HDR = 1;
    };
  };

  environment.etc."skel/.steam/steam/config/config.vdf".text = ''
    "CompatToolMapping"
    {
        "*"
        {
            "name"  "proton-ge-custom"
            "config"    ""
            "priority"  "250"
        }
    }
  '';
}
