{ pkgs, ... }:

{
  virtualisation.waydroid.enable = true;
  services.geoclue2.enable = true;
  programs.kdeconnect.enable = true;

  environment = {
    systemPackages = with pkgs; [
      android-tools
    ];
  };
}
