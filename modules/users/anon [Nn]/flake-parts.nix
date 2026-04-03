{ inputs, lib, ... }:

let
  hostsDir = "${inputs.self}/modules/hosts";
  hostNames =
    lib.pipe (builtins.readDir hostsDir) [
      (lib.filterAttrs (name: type: type == "directory"))
      builtins.attrNames
      (map (name: builtins.head (lib.splitString " " name)))
    ];

  hm = inputs.self.modules.homeManager;

  # Desktop-environment HM modules to add per host on the standalone HM path.
  # On the NixOS path these are injected by the system feature modules via
  # home-manager.sharedModules (nixos.hyprland / nixos.kde).
  deModules = {
    anon = [ hm.hyprland hm.theme ];
    nona = [ hm.hyprland hm.theme ];
    vm   = [ hm.kde ];
    wsl  = [ hm.theme ];
  };

  mkHm = inputs.self.lib.mkHomeManager "x86_64-linux";
in
{
  flake.homeConfigurations = lib.mkMerge (
    map (name: mkHm name (deModules.${name} or [ ])) hostNames
  );
}
