{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "nona";
  keymap = "dvorak";
  primaryMonitor = "eDP-1";
in
{
  flake.modules.nixos.nona =
    { pkgs, config, ... }:
    let
      kernel = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
    in
    {
      imports =
        with inputs.self.modules.nixos;
        [
          appimage
          development
          flatpak
          gpu-amd
          hyprland
          keyd
          mounts
          mpv
          obs
          podman
          qemu
          steam
          system-default
          ucodenix
          user-mbwilding
          waydroid
          wine
          wireguard-nona
          wireshark
        ]
        ++ [
          ./_hardware-configuration.nix
          ./_audio.nix
        ];

      home-manager.sharedModules = [
        ./_hyprland.nix
        # (
        #   { pkgs, ... }:
        #   {
        #     home.packages = with pkgs; [
        #       # package
        #     ];
        #   }
        # )
      ];

      networking.hostName = hostName;
      console.keyMap = keymap;
      services.xserver.xkb.variant = keymap;
      boot.kernelPackages = kernel;

      hardware = {
        xone.enable = true;
      };

      services = {
        upower.enable = true;
      };

      host.primaryMonitor = primaryMonitor;

      environment = {
        sessionVariables = {
          WAYLANDDRV_PRIMARY_MONITOR = config.host.primaryMonitor;
        };
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName (
    with inputs.self.modules.homeManager;
    [
      {
        _module.args.primaryMonitor = primaryMonitor;
      }

      ./_hyprland.nix
      hyprland
    ]
  );
}
