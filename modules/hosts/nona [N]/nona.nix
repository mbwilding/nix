{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "nona";
  keymap = "dvorak";
  primaryMonitor = "eDP-1";
  stateVersion = "25.11";
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
          gpu-amd
          hyprland
          niri
          keyd
          mounts
          mpv
          obs
          podman
          printing
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
        ./_niri.nix
        # (
        #   { pkgs, ... }:
        #   {
        #     home.packages = with pkgs; [
        #       # package
        #     ];
        #   }
        # )
      ];

      boot.kernelPackages = kernel;
      console.keyMap = keymap;
      host.primaryMonitor = primaryMonitor;
      networking.hostName = hostName;
      services.xserver.xkb.variant = keymap;
      system.stateVersion = stateVersion;

      hardware = {
        xone.enable = true;
      };

      services = {
        upower.enable = true;
      };
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

      ./_niri.nix
      niri
    ]
  );
}
