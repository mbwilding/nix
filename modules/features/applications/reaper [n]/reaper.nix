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
      configFiles = [
        "reaper.ini"
        "reaper-mouse.ini"
        "reaper-themeconfig.ini"
        "reaper-midihw-alsa.ini"
        "reaper-midihw-linux.ini"
        "reaper-fxtags.ini"
      ];
    in
    {
      home = {
        packages = with pkgs; [
          reaper
          reaper-sws-extension
          reaper-reapack-extension
        ];
      };

      # REAPER rewrites its own config files at runtime (window state, recent
      # projects, plugin scans, colour tweaks, etc), so these are seeded once
      # as writable copies rather than symlinked from the nix store.
      home.activation.reaperInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${configDir}/Audio"

        ${lib.concatMapStringsSep "\n" (name: ''
          if [ ! -f "${configDir}/${name}" ]; then
            $DRY_RUN_CMD mkdir -p "${configDir}"
            $DRY_RUN_CMD cp ${./config + "/${name}"} "${configDir}/${name}"
            $DRY_RUN_CMD chmod 644 "${configDir}/${name}"
          fi
        '') configFiles}
      '';
    };
}
