{ pkgs, ... }:

{
  virtualisation.waydroid.enable = true;
  networking.nftables.enable = true;
  services.geoclue2.enable = true;
  programs.kdeconnect.enable = true;

  environment = {
    systemPackages = with pkgs; [
      android-tools
      waydroid-helper
    ];
  };

  systemd = {
    packages = [ pkgs.waydroid-helper ];
    services.waydroid-mount.wantedBy = [ "multi-user.target" ];
  };
}
