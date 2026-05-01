{ inputs, lib, ... }:

let
  hostsDir = "${inputs.self}/modules/hosts";
  hostNames = lib.pipe (builtins.readDir hostsDir) [
    (lib.filterAttrs (name: type: type == "directory"))
    builtins.attrNames
    (map (name: builtins.head (lib.splitString " " name)))
  ];

  droidHostNames = builtins.filter (name: name == "droid") hostNames;
in
{
  flake.nixOnDroidConfigurations = lib.mkMerge (map inputs.self.lib.mkNixOnDroid droidHostNames);
}
