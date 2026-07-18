{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "anon";
  primaryMonitor = "HDMI-A-1";

  features = [
    "appimage"
    "audio"
    "claudecode"
    "development"
    "flatpak"
    "gpu-nvidia"
    "gui"
    "hyprland"
    "llama-swap"
    "mounts"
    "mpv"
    "obs"
    "podman"
    "printing"
    "proxy"
    "proxychains"
    "qemu"
    "solaar"
    "steam"
    "streamcontroller"
    "swap"
    "system-default"
    "ucodenix"
    "user-mbwilding"
    "waydroid"
    "wine"
    "wireshark"
  ];

  featureModules = inputs.self.lib.mkFeatures features;

  homeManagerExtraModules = [
    {
      _module.args.primaryMonitor = primaryMonitor;
    }

    ./_hyprland.nix

    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          davinci-resolve-studio
        ];
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
        ./_audio.nix
        ./_hardware-configuration.nix
        ./_sunshine.nix
      ];

      home-manager.sharedModules = homeManagerModules;

      boot.kernelPackages = kernel;
      host.primaryMonitor = primaryMonitor;
      networking.hostName = hostName;

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

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
