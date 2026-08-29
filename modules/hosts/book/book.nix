{ inputs, ... }:

let
  arch = "x86_64-linux";
  hostName = "book";
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
    "gui"
    "hyprland"
    "keyd"
    "mounts"
    "mpv"
    "podman"
    "printing"
    "proxy"
    "swap"
    "system-default"
    "user-mbwilding"
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

    (
      { pkgs, ... }:
      {
        home.packages = with pkgs; [];
      }
    )
  ];

  homeManagerModules = featureModules.homeManager ++ homeManagerExtraModules;
in
{
  flake.modules.nixos.${hostName} =
    { ... }:
    {
      imports = featureModules.nixos ++ [
        ./_hardware-configuration.nix
        ./_audio.nix
        inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
      ];

      hardware.microsoft-surface.kernelVersion = "stable";
      home-manager.sharedModules = homeManagerModules;
      console.keyMap = keymap;
      host.primaryMonitor = primaryMonitor;
      networking.hostName = hostName;
      services.xserver.xkb.variant = keymap;

      services = {
        upower.enable = true;
      };


      system.stateVersion = "26.05";
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixOS arch hostName;

  flake.homeConfigurations = inputs.self.lib.mkHomeManager arch hostName homeManagerModules;
}
