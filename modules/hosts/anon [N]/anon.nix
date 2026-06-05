{ inputs, ... }:

{
  flake.modules.nixos.anon =
    { pkgs, config, ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          # lutris
          appimage
          flatpak
          mounts
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
          wine
          wireshark

          hyprland
          # kde
        ]
        ++ [
          ./_audio.nix
          ./_hardware-configuration.nix
        ];

      home-manager.sharedModules = [
        # ./_kde.nix

        ./_ghostty.nix
        ./_hyprland.nix
        ./_noctalia.nix

        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              davinci-resolve-studio
            ];
          }
        )
      ];

      networking.hostName = "anon";

      host.primaryMonitor = "HDMI-A-1";

      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;

      environment = {
        sessionVariables = {
          WAYLANDDRV_PRIMARY_MONITOR = config.host.primaryMonitor;
        };
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
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anon";

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "anon" (
    with inputs.self.modules.homeManager;
    [
      { _module.args.primaryMonitor = "HDMI-A-1"; }

      ./_ghostty.nix

      ./_hyprland.nix
      hyprland

      # kde
    ]
  );
}
