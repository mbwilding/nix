{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "anon";
  primaryMonitor = "HDMI-A-1";
in
{
  flake.modules.nixos.${hostName} =
    { pkgs, ... }:
    let
      kernel = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
    in
    {
      imports =
        with inputs.self.modules.nixos;
        [
          appimage
          audio
          development
          flatpak
          gpu-nvidia
          hyprland
          llama-swap
          mounts
          mpv
          obs
          podman
          printing
          qemu
          solaar
          steam
          streamcontroller
          system-default
          ucodenix
          user-mbwilding
          waydroid
          wine
          wireshark
        ]
        ++ [
          ./_audio.nix
          ./_hardware-configuration.nix
          ./_sunshine.nix
        ];

      home-manager.sharedModules = [
        # ./_ghostty.nix

        ./_hyprland.nix
        # ./_niri.nix

        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              davinci-resolve-studio
            ];
          }
        )
      ];

      networking.hostName = hostName;
      host.primaryMonitor = primaryMonitor;
      boot.kernelPackages = kernel;

      hardware = {
        xone.enable = true;
        nvidia-container-toolkit.enable = true;
      };

      services = {
        hardware = {
          openrgb.enable = true;
        };
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName (
    with inputs.self.modules.homeManager;
    [
      {
        _module.args.primaryMonitor = primaryMonitor;
      }

      # ./_ghostty.nix

      ./_hyprland.nix
      hyprland

      # ./_niri.nix
      # niri

      streamcontroller
    ]
  );
}
