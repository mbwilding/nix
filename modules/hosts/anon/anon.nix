{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "anon";
  primaryMonitor = "HDMI-A-1";

  features = [
    "affinity"
    "appimage"
    "audio"
    "claude-desktop"
    "claudecode"
    "copilot-cli"
    "development"
    "flatpak"
    "gpu-nvidia"
    "gui"
    "hyprland"
    "lutris"
    "mounts"
    "mpv"
    "obs"
    "podman"
    "printing"
    "proxy"
    "qemu"
    "solaar"
    "steam"
    "streamcontroller"
    "swap"
    "system-default"
    "ucodenix"
    "user-mbwilding"
    "user-work"
    "vm-curator"
    "waydroid"
    "wine"
    "wireshark"
    # "llama-swap"
  ];

  featureModules = inputs.self.lib.mkFeatures features;

  homeManagerExtraModules = [
    {
      _module.args.primaryMonitor = primaryMonitor;
    }

    ./_hyprland.nix
    # ./_kitty.nix

    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          davinci-resolve-studio
          heroic
        ];
      }
    )
  ];

  homeManagerModules = featureModules.homeManager ++ homeManagerExtraModules;
in
{
  flake.modules.nixos.${hostName} =
    {
      lib,
      pkgs,
      pkgsMaster,
      ...
    }:
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

      systemd.services.wifi-disable-default = {
        description = "Disable WiFi radio by default on boot";
        after = [ "NetworkManager.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
        };
      };

      hardware = {
        xone.enable = true;
        nvidia-container-toolkit.enable = true;
      };

      services = {
        hardware = {
          openrgb.enable = true;
        };
      };

      programs = {
        bazecor = {
          enable = true;
          package = pkgsMaster.bazecor.overrideAttrs (old: {
            buildCommand =
              lib.replaceStrings
                [
                  "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
                ]
                [ "--ozone-platform=x11" ]
                old.buildCommand;
          });
        };
      };

      system.stateVersion = "26.05";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
