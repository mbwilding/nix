{ lib, moduleLocation, ... }:

let
  addInfo =
    class: moduleName:
    if class == "generic" then
      module: module
    else
      module:
      { ... }:
      {
        key = "${class}.${moduleName}";
        _class = class;
        _file = "${toString moduleLocation}#modules.${lib.strings.escapeNixIdentifier class}.${lib.strings.escapeNixIdentifier moduleName}";
        imports = [ module ];
      };
in
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    description = "Groups of modules published by the flake, keyed by class and name so repeated imports are deduplicated.";
    apply = lib.mapAttrs (k: lib.mapAttrs (addInfo k));
  };
}
