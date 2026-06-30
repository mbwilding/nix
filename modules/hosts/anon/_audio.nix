{ ... }:

{
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      extraConfig = {
        pipewire."92-low-latency" = {
          context.properties.default.clock = {
            rate = 44100;
            quantum = 128;
            min-quantum = 128;
            max-quantum = 128;
          };
        };
        pipewire-pulse."92-low-latency" = {
          context.modules = [
            {
              name = "libpipewire-module-protocol-pulse";
              args.pulse = {
                default.req = "128/44100";
                min.req = "128/44100";
                max.req = "128/44100";
                min.quantum = "128/44100";
                max.quantum = "128/44100";
              };
            }
          ];
          stream.properties = {
            node.latency = "128/44100";
            resample.quality = 1;
          };
          session.properties = {
            "default.sink" = "Headphones";
            "default.volume" = "1.0";
          };
        };

        pipewire-pulse."95-babyfacepro-split" = {
          pulse.cmd = [
            {
              cmd = "load-module";
              args =
                "module-remap-sink sink_name=Speakers master=alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.pro-output-0 channels=2 channel_map=front-left,front-right master_channel_map=aux0,aux1 resample_method=copy sink_properties='node.description=Speakers device.description=Speakers node.nick=Speakers'";
            }
            {
              cmd = "load-module";
              args =
                "module-remap-sink sink_name=Headphones master=alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.pro-output-0 channels=2 channel_map=front-left,front-right master_channel_map=aux2,aux3 resample_method=copy sink_properties='node.description=Headphones device.description=Headphones node.nick=Headphones'";
            }
          ];
          session.properties."default.sink" = "Headphones";
        };
      };

      wireplumber.extraConfig."99-rename-devices" = {
        "monitor.alsa.rules" = [
          {
            matches = [ { "device.name" = "alsa_card.pci-0000_01_00.1"; } ];
            actions.update-props = {
              "device.description" = "HDMI";
              "device.nick" = "Nvidia HDMI";
              "device.disabled" = true;
            };
          }
          {
            matches = [ { "device.name" = "alsa_card.pci-0000_17_00.1"; } ];
            actions.update-props = {
              "device.description" = "In-Built HDMI";
              "device.nick" = "Radeon HDMI";
              "node.disabled" = true;
            };
          }
          {
            matches = [ { "device.name" = "alsa_card.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00"; } ];
            actions.update-props = {
              "device.description" = "Babyface";
              "device.nick" = "Babyface";
              "device.profile" = "pro-audio";
            };
          }
          {
            matches = [ { "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo"; } ];
            actions.update-props = {
              "node.description" = "Nvidia HDMI";
              "node.nick" = "LG TV";
              "node.disabled" = true;
            };
          }
          {
            matches = [
              { "node.name" = "alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo"; }
            ];
            actions.update-props = {
              "node.description" = "Babyface";
              "node.nick" = "Babyface Out";
            };
          }
          {
            matches = [
              { "node.name" = "alsa_input.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo"; }
            ];
            actions.update-props = {
              "node.description" = "Babyface";
              "node.nick" = "Babyface In";
            };
          }
        ];
      };
    };

    udev.extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
    '';
  };
}
