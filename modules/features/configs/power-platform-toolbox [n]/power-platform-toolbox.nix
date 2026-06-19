{ ... }:

{
  flake.modules.homeManager.power-platform-toolbox =
    {
      lib,
      pkgs,
      secrets,
      ...
    }:
    let
      connectionsFile = pkgs.writeText "connections.json" (builtins.toJSON secrets.dynamicsCredentials);
      userSettingsFile = pkgs.writeText "user-settings.json" (
        builtins.toJSON {
          autoUpdate = false;
          connections = [ ];
          connectionsSort = "last-used";
          cspConsents = {
            de178113-27a1-4acb-b8f4-6b62ef0021e0 = {
              allowed = true;
              required = [
                "https://raw.githubusercontent.com"
                "https://raw.githubusercontent.com/LinkeD365/*"
              ];
              optional = [ ];
            };
          };
          deprecatedToolsVisibility = "hide-all";
          favoriteTools = [
            "3219642b-638a-45c8-97d5-34d1fbc0d3ba"
            "0db0368c-e0dd-4575-bdf0-7495a43ef660"
          ];
          installId = "37e6a270-227d-48e6-ab31-2736ae4982b6";
          installedTools = [
            "3219642b-638a-45c8-97d5-34d1fbc0d3ba"
            "0db0368c-e0dd-4575-bdf0-7495a43ef660"
          ];
          language = "en";
          lastUsedTools = [ ];
          notificationDuration = 5000;
          restoreSessionOnStartup = true;
          showDebugMenu = true;
          terminalFont = "NeoSpleen Nerd Font";
          theme = "system";
          toolConnections = { };
          toolSecondaryConnections = { };
        }
      );
      configDir = "$HOME/.config/powerplatform-toolbox";
    in
    {
      home.activation.powerPlatformToolbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${configDir}"

        if [ ! -f "${configDir}/connections.json" ]; then
          $DRY_RUN_CMD cp ${connectionsFile} "${configDir}/connections.json"
        fi

        if [ ! -f "${configDir}/user-settings.json" ]; then
          $DRY_RUN_CMD cp ${userSettingsFile} "${configDir}/user-settings.json"
        fi
      '';
    };
}
