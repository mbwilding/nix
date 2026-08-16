{ ... }:

{
  flake.modules.homeManager.reaper =
    {
      lib,
      pkgs,
      ...
    }:

    let
      configDir = "$HOME/.config/REAPER";
      walk =
        relDir: dir:
        let
          entries = builtins.readDir dir;
        in
        lib.concatMap (
          name:
          let
            relPath = if relDir == "" then name else "${relDir}/${name}";
          in
          if name == ".gitignore" then
            [ ]
          else if entries.${name} == "directory" then
            walk relPath (dir + "/${name}")
          else
            [ relPath ]
        ) (builtins.attrNames entries);
      configFiles = walk "" ./config;
    in
    {
      home = {
        packages = with pkgs; [
          reaper
          reaper-sws-extension
          reaper-reapack-extension
        ];
      };

      home.activation.reaperInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${configDir}"

        ${lib.concatMapStringsSep "\n" (name: ''
          if [ ! -f "${configDir}/${name}" ]; then
            mkdir -p "$(dirname "${configDir}/${name}")"
            cp "${./config}/${name}" "${configDir}/${name}"
            chmod 644 "${configDir}/${name}"
          fi
        '') configFiles}
      '';
    };
}
