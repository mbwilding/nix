{ ... }:

{
  flake.modules.nixos.obs =
    { pkgs, config, ... }:
    {
      boot.kernelModules = [
        "v4l2loopback"
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

      services.pipewire.extraConfig.pipewire."90-obs-virtual-audio" = {
        "context.objects" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "obs-monitor-sink";
              "node.description" = "OBS Monitor";
              "media.class" = "Audio/Sink";
              "audio.position" = "FL,FR";
              "object.linger" = true;
            };
          }
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "obs-virtual-mic";
              "node.description" = "OBS Mic";
              "media.class" = "Audio/Source/Virtual";
              "audio.position" = "FL,FR";
              "object.linger" = true;
            };
          }
        ];
      };
    };

  flake.modules.homeManager.obs =
    { pkgs, config, ... }:
    {
      systemd.user.services.obs-virtual-mic-link = {
        Unit = {
          Description = "Link OBS monitor sink to OBS virtual mic";
          After = [ "pipewire.service" ];
          Requires = [ "pipewire.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          ExecStart = pkgs.writeShellScript "obs-virtual-mic-link" ''
            ${pkgs.pipewire}/bin/pw-link obs-monitor-sink:monitor_FL obs-virtual-mic:input_FL
            ${pkgs.pipewire}/bin/pw-link obs-monitor-sink:monitor_FR obs-virtual-mic:input_FR
          '';
        };
        Install.WantedBy = [ "default.target" ];
      };

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-vaapi
        ];
      };

      xdg.desktopEntries."com.obsproject.Studio" = {
        name = "OBS Studio";
        exec = "obs --startvirtualcam --scene Camera %F";
        icon = "com.obsproject.Studio";
        terminal = false;
        categories = [
          "AudioVideo"
          "Recorder"
        ];
      };
    };
}
