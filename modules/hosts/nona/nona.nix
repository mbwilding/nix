{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "nona";
  primaryMonitor = "eDP-1";

  features = [
    "appimage"
    "audio"
    "claude-code"
    "development"
    "flatpak"
    "gpu-amd"
    "gui"
    "hyprland"
    "keyd-dvorak"
    "lutris"
    "mango"
    "mounts"
    "mpv"
    "niri"
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
    "vscode"
    "waydroid"
    "wifi"
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
    ./_mango.nix
    ./_niri.nix

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
    { lib, pkgs, ... }:
    let
      # kernel = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
      kernel = pkgs.linuxPackages_latest;
    in
    {
      imports = featureModules.nixos ++ [
        ./_hardware-configuration.nix
        ./_audio.nix
      ];

      home-manager.sharedModules = homeManagerModules;

      boot.kernelPackages = kernel;
      boot.extraModprobeConfig = ''
        options rtw89_pci disable_aspm_l1=Y disable_aspm_l1ss=Y disable_clkreq=Y
        options rtw89_core disable_ps_mode=Y
      '';
      host = {
        keymap = "dvorak";
        primaryMonitor = primaryMonitor;
        waylandSession.defaultSession = "mango";
      };
      networking.hostName = hostName;

      hardware = {
        xone.enable = true;
        xpad-noone.enable = false;
      };

      services = {
        upower.enable = true;
      };

      system.stateVersion = "25.11";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
