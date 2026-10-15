{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "stealth";
  primaryMonitor = "eDP-1";

  features = [
    "appimage"
    "audio"
    "claude-code"
    "development"
    "flatpak"
    "gpu-amd"
    "gpu-nvidia"
    "gui"
    "hyprland"
    "keyd-dvorak"
    "lutris"
    "mounts"
    "mpv"
    "obs"
    "podman"
    "printing"
    "proxy"
    "qemu"
    "secure-boot"
    "steam"
    "swap"
    "system-default"
    "ucodenix"
    "user-mbwilding"
    "user-work"
    "vm-curator"
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
      # kernel = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4;
      kernel = pkgs.linuxPackages_latest;
    in
    {
      imports = featureModules.nixos ++ [
        ./_hardware-configuration.nix
        # ./_audio.nix
      ];

      home-manager.sharedModules = homeManagerModules;

      boot.kernelPackages = kernel;
      host = {
        keymap = "dvorak";
        primaryMonitor = primaryMonitor;
      };
      networking.hostName = hostName;

      hardware = {
        xone.enable = true;

        nvidia = {
          powerManagement.enable = true;
          powerManagement.finegrained = true;
          prime = {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
            amdgpuBusId = "PCI:101:0:0";
            nvidiaBusId = "PCI:100:0:0";
          };
        };
      };

      services = {
        upower.enable = true;
      };

      system.stateVersion = "26.05";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
