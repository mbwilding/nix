{ inputs, ... }:

let
  keymap = "dvorak";
in
{
  flake.modules.nixos.nona =
    { pkgs, config, ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          # lutris
          amd
          appimage
          flatpak
          mounts
          mpv
          podman
          qemu
          steam
          system-default
          ucodenix
          user-anon
          waydroid
          wireguard-nona
          wireshark

          hyprland
          # kde
        ]
        ++ [
          ./_hardware-configuration.nix
          ./_audio.nix
          ./_keyd.nix
        ];

      home-manager.sharedModules = [
        ./_hyprland.nix

        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              # package
            ];
          }
        )
      ];

      networking.hostName = "nona";

      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;

      console.keyMap = keymap;
      services.xserver.xkb.variant = keymap;

      hardware = {
        xone.enable = true;
      };

      services = {
        upower.enable = true;
      };

      host.primaryMonitor = "eDP-1";

      environment = {
        sessionVariables = {
          WAYLANDDRV_PRIMARY_MONITOR = config.host.primaryMonitor;
        };
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "nona";

  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "nona" (
    with inputs.self.modules.homeManager;
    [
      { _module.args.primaryMonitor = "eDP-1"; }

      hyprland
      ./_hyprland.nix

      # kde
    ]
  );
}
