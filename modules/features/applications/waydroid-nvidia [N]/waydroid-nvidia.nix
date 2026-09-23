{ inputs, ... }:

{
  flake.modules.nixos.waydroid-nvidia =
    { pkgs, ... }:
    let
      wnv = inputs.waydroid-nvidia-nix.packages.${pkgs.system}.waydroid-nvidia-full;
    in
    {
      # Stock Waydroid's hwcomposer can't render on nvidia proprietary drivers
      # (it segfaults immediately, crash-looping the container). This proxies
      # Vulkan (Mesa Venus) over a socket to a host-side renderer that issues
      # the real Vulkan calls against nvidia instead.
      # https://github.com/Shiro836/waydroid-nvidia
      virtualisation.waydroid.package = wnv;

      services.udev.packages = [ wnv ];
      systemd.tmpfiles.packages = [ wnv ];

      systemd.user.services.wd-venus = {
        description = "Venus vtest render server for waydroid-nvidia";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${wnv}/lib/waydroid-nvidia/virgl_test_server --venus --multi-clients --socket-path /run/waydroid-venus/venus.sock";
          Environment = [
            "RENDER_SERVER_EXEC_PATH=${wnv}/lib/waydroid-nvidia/virgl_render_server"
            "LD_LIBRARY_PATH=${wnv}/lib/waydroid-nvidia:${pkgs.vulkan-loader}/lib"
          ];
          Restart = "on-failure";
          RestartSec = 1;
        };
      };
    };
}
