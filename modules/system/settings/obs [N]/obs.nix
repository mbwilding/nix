{ ... }:

{
  flake.modules.nixos.obs =
    { pkgs, config, ... }:
    {
      boot.kernelModules = [
        "v4l2loopback"
        "snd-aloop"
      ];

      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=10 card_label="OBS Cam" exclusive_caps=1
      '';

      boot.extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback
      ];

      security.polkit.enable = true;

      environment.systemPackages = with pkgs; [
        obs-studio
        v4l-utils
      ];
    };
}
