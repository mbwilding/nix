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
          keyd
          mounts
          mpv
          obs
          podman
          printing
          qemu
          steam
          swap
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

      home-manager.sharedModules = with inputs.self.modules.homeManager; [
        claudecode
        gui
        proxy
        proxychains

        ./_hyprland.nix
        hyprland
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

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName (
    with inputs.self.modules.homeManager;
    [
      {
        _module.args.primaryMonitor = primaryMonitor;
      }

      claudecode
      gui
      proxy
      proxychains

      ./_hyprland.nix
      hyprland
    ]
  );
}
