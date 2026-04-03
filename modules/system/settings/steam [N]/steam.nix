{ ... }:

{
  flake.modules.nixos.steam =
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
    };
}
