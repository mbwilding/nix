{ ... }:

{
  flake.modules.homeManager.vscode =
    { pkgs, lib, ... }:

    let
      extensionFiles = lib.filterAttrs (
        name: type: type == "regular" && lib.hasPrefix "_" name && lib.hasSuffix ".nix" name
      ) (builtins.readDir ./extensions);

      loaded = lib.mapAttrsToList (name: _: pkgs.callPackage (./extensions + "/${name}") { }) extensionFiles;
    in
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;

        profiles.default = {
          extensions = map (e: e.extension) loaded;
          userSettings = lib.foldl' lib.recursiveUpdate { } (map (e: e.settings or { }) loaded);
        };
      };
    };
}
