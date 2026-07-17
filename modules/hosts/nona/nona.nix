{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "nona";
  keymap = "dvorak";
  primaryMonitor = "eDP-1";
  stateVersion = "25.11";

  features = [
    "appimage"
    "audio"
    "claudecode"
    "development"
    "flatpak"
    "gpu-amd"
    "gui"
    "hyprland"
    "keyd"
    "mounts"
    "mpv"
    "obs"
    "podman"
    "printing"
    "proxy"
    "proxychains"
    "qemu"
    "steam"
    "swap"
    "system-default"
    "ucodenix"
    "user-mbwilding"
    "waydroid"
    "wine"
    "wireguard-nona"
    "wireshark"
  ];

  featureModules = inputs.self.lib.mkFeatures features;

  homeManagerExtraModules = [
    {
      _module.args.primaryMonitor = primaryMonitor;
    }

    ./_hyprland.nix
  ];

  homeManagerModules = featureModules.homeManager ++ homeManagerExtraModules;
in
{
  flake.modules.nixos.${hostName} =
    { pkgs, ... }:
    let
      kernel = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
    in
    {
      imports = featureModules.nixos ++ [
        ./_hardware-configuration.nix
        ./_audio.nix
      ];

      home-manager.sharedModules = homeManagerModules;

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

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
