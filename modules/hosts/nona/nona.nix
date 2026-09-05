{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "nona";
  keymap = "dvorak";
  primaryMonitor = "eDP-1";

  features = [
    "appimage"
    "audio"
    "claude-desktop"
    "claudecode"
    "copilot-cli"
    "development"
    "flatpak"
    "gpu-amd"
    "gui"
    "hyprland"
    "keyd"
    "lutris"
    "mounts"
    "mpv"
    "obs"
    "podman"
    "printing"
    "proxy"
    "qemu"
    "steam"
    "swap"
    "system-default"
    "ucodenix"
    "user-mbwilding"
    "user-work"
    "vm-curator"
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

    (
      {
        pkgs,
        lib,
        secrets,
        ...
      }:
      {
        home.packages =
          with pkgs;
          [
            heroic
          ]
          ++ map (name: lib.attrByPath (lib.splitString "." name) null pkgs) secrets.packages;
      }
    )
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

      hardware = {
        xone.enable = true;
      };

      services = {
        upower.enable = true;
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
