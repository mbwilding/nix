{ ... }:

{
  flake.modules.nixos.waydroid =
    { pkgs, ... }:
    {
      virtualisation.waydroid.enable = true;
      networking.nftables.enable = true;
      services.geoclue2.enable = true;
      programs.kdeconnect.enable = true;

      # Waydroid hardcodes nvidia as an unsupported render GPU and falls back to
      # the first other /dev/dri/renderD* node, even when nvidia is the GPU
      # actually driving the display (hybrid amdgpu+nvidia). That mismatch
      # produces a running but blank Waydroid window. Drop nvidia from the
      # blocklist so init/auto-detection picks the right node.
      nixpkgs.overlays = [
        (_final: prev: {
          waydroid = prev.waydroid.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace tools/helpers/gpu.py \
                --replace-fail 'unsupported = ["nvidia"]' 'unsupported = []'
            '';
          });
        })
      ];

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
