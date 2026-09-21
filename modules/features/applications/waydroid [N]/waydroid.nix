{ ... }:

{
  flake.modules.nixos.waydroid =
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

        # Audio runs as a system-wide pipewire instance (see host _audio.nix), so the
        # per-user pipewire-pulse socket waydroid's lxc hook expects doesn't exist.
        # Recreate it as a symlink to the real system socket on every user login.
        user.tmpfiles.rules = [
          "d %t/pulse 0755 - - -"
          "L+ %t/pulse/native - - - - /run/pulse/native"
        ];
      };
    };
}
