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

      services.pipewire.wireplumber.extraConfig."99-rename-obs-loopback" = {
        "monitor.alsa.rules" = [
          {
            matches = [ { "device.name" = "alsa_card.platform-snd_aloop.0"; } ];
            actions.update-props = {
              "device.description" = "Loopback";
              "device.nick" = "OBS Loopback";
            };
          }
          {
            matches = [ { "node.name" = "alsa_output.platform-snd_aloop.0.analog-stereo"; } ];
            actions.update-props = {
              "node.description" = "Loopback";
              "node.nick" = "OBS Loopback";
            };
          }
          {
            matches = [ { "node.name" = "alsa_input.platform-snd_aloop.0.analog-stereo"; } ];
            actions.update-props = {
              "node.description" = "Loopback";
              "node.nick" = "OBS Loopback (Monitor)";
            };
          }
        ];
      };
    };

  flake.modules.homeManager.obs =
    { pkgs, config, ... }:
    {
      programs.obs-studio = {
        enable = true;
        # plugins = [];
      };
    };
}
