{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/nvidia.nix

    # ../../modules/system/kde.nix
    ../../modules/system/hyprland.nix

    ../../modules/system/default.nix
    ../../modules/system/obs.nix
    ../../modules/system/steam.nix
    ../../modules/system/wireguard.nix
    ../../modules/system/wireshark.nix
    ../../modules/system/mounts.nix
  ];

  networking.hostName = "anon";

  environment = {
    sessionVariables = {
      WAYLANDDRV_PRIMARY_MONITOR = "HDMI-A-1";
    };
  };

  hardware = {
    xone.enable = true;
    nvidia-container-toolkit.enable = true;
  };

  services = {
    hardware = {
      openrgb.enable = true;
    };

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
            "default.sink" = "alsa_output.usb-BabyfaceProAnalogStereo";
            "default.volume" = "1.0";
          };
        };
      };
    };

    udev.extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
    '';
  };

  programs = {
    bazecor.enable = true;
  };

  system.stateVersion = "25.11";
}
