{ inputs, ... }:

{
  flake.modules.nixos.anon =
    { pkgs, config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        appimage
        flatpak
        lutris
        mpv
        nvidia
        obs
        podman
        qemu
        solaar
        steam
        system-default
        ucodenix
        user-anon
        waydroid
        wireshark
        # mounts

        hyprland
        # kde
      ] ++ [
        ./_hardware-configuration.nix
      ];

      home-manager.sharedModules = [
        ./_ghostty.nix

        ./_hyprland.nix
        # ./_kde.nix
      ];

      networking.hostName = "anon";

      host.primaryMonitor = "HDMI-A-1";

      environment = {
        sessionVariables = {
          WAYLANDDRV_PRIMARY_MONITOR = config.host.primaryMonitor;
        };
        systemPackages = with pkgs; [
          davinci-resolve-studio
        ];
      };

      hardware = {
        xone.enable = true;
        nvidia-container-toolkit.enable = true;
      };

      services = {
        sunshine = {
          enable = false;
          openFirewall = true;
          autoStart = true;
          capSysAdmin = true;
          settings = {
            sunshine_name = "anon";
            audio_sink = "alsa_output.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo";
            install_steam_audio_drivers = "enabled";
            adapter_name = "/dev/dri/renderD128";
            capture = "nvfbc";
            encoder = "nvenc";
            nvenc_preset = 1;
          };
        };

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
                "node.description" = "Babyface Pro";
                "node.nick" = "Babyface Pro Out";
              };
            }
            {
              matches = [
                { "node.name" = "alsa_input.usb-RME_Babyface_Pro__71972575__77EB3EDA0B95BC8-00.analog-stereo"; }
              ];
              actions.update-props = {
                "node.description" = "Babyface Pro";
                "node.nick" = "Babyface Pro In";
              };
            }
          ];
        };
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anon";

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "anon" (
    with inputs.self.modules.homeManager;
    [
      ./_ghostty.nix

      ./_hyprland.nix
      hyprland
      theme

      # kde
    ]
  );
}
