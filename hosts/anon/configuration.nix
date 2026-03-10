{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/nvidia.nix

    # ../../modules/system/kde.nix
    ../../modules/system/hyprland.nix

    ../../modules/system/default.nix
    ../../modules/system/mounts.nix
    ../../modules/system/obs.nix
    ../../modules/system/podman.nix
    # ../../modules/system/docker.nix
    ../../modules/system/steam.nix
    ../../modules/system/wireguard.nix
    ../../modules/system/wireshark.nix
    ../../modules/system/appimage.nix
  ];

  networking.hostName = "anon";

  # Disable the integrated Radeon GPU (Raphael)
  boot.kernelParams = [ "pci-stub.ids=1002:164e" ];
  boot.kernelModules = [ "pci-stub" ];

  environment = {
    sessionVariables = {
      WAYLANDDRV_PRIMARY_MONITOR = "HDMI-A-1";
    };
    systemPackages = with pkgs; [
      solaar
    ];
  };

  hardware = {
    xone.enable = true;
    nvidia-container-toolkit.enable = true;
    logitech.wireless.enable = true;
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

    pipewire.wireplumber.extraConfig."99-rename-devices" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_01_00.1"; } ];
          actions.update-props = {
            "device.description" = "HDMI";
            "device.nick" = "Nvidia HDMI";
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
            "device.description" = "Babyface Pro";
            "device.nick" = "Babyface Pro";
          };
        }
        {
          matches = [ { "device.name" = "alsa_card.platform-snd_aloop.0"; } ];
          actions.update-props = {
            "device.description" = "Loopback";
            "device.nick" = "OBS Loopback";
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
          matches = [ { "node.name" = "alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo"; } ];
          actions.update-props = {
            "node.description" = "Babyface Pro";
            "node.nick" = "Babyface Pro Out";
          };
        }
        {
          matches = [ { "node.name" = "alsa_input.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo"; } ];
          actions.update-props = {
            "node.description" = "Babyface Pro";
            "node.nick" = "Babyface Pro In";
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

  nix.settings = {
    download-buffer-size = 5 * 1024 * 1024 * 1024; # GB
  };

  system.stateVersion = "25.11";
}
