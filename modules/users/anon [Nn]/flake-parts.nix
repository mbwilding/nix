{ inputs, lib, ... }:

let
  hostsDir = "${inputs.self}/modules/hosts";
  hostNames = lib.pipe (builtins.readDir hostsDir) [
    (lib.filterAttrs (name: type: type == "directory"))
    builtins.attrNames
    (map (name: builtins.head (lib.splitString " " name)))
  ];

  nixosHostNames = builtins.filter (name: name != "droid") hostNames;
  droidHostNames = builtins.filter (name: name == "droid") hostNames;

  hm = inputs.self.modules.homeManager;

  deModules = {
    anon = [
      hm.hyprland
      hm.theme
    ];
    nona = [
      hm.hyprland
      hm.theme
    ];
    vm = [ hm.kde ];
    wsl = [ hm.theme ];
    droid = [ hm.theme ];
  };

  mkHm = inputs.self.lib.mkHomeManager "x86_64-linux";
in
{
  flake.homeConfigurations = lib.mkMerge (
    map (name: mkHm name (deModules.${name} or [ ])) nixosHostNames
  );

  flake.nixOnDroidConfigurations = lib.mkMerge (map inputs.self.lib.mkNixOnDroid droidHostNames);
}
