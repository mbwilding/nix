{ ... }:

{
  flake.modules.homeManager.power-platform-toolbox =
    { lib, pkgs, secrets, ... }:
    let
      connectionsFile = pkgs.writeText "connections.json" (builtins.toJSON secrets.dynamicsCredentials);
      userSettingsFile = pkgs.writeText "user-settings.json" (builtins.toJSON {
        theme = "system";
        language = "en";
        autoUpdate = false;
        terminalFont = "NeoSpleen Nerd Font";
        notificationDuration = 5000;
        showDebugMenu = true;
        deprecatedToolsVisibility = "hide-all";
        connections = [ ];
        installedTools = [
          "179a21f4-c89c-4757-8c57-0fd8c7d47ddb"
          "d4b881a6-d7ac-401e-a6f8-5830af903da8"
          "de178113-27a1-4acb-b8f4-6b62ef0021e0"
          "0db0368c-e0dd-4575-bdf0-7495a43ef660"
        ];
        lastUsedTools = [ ];
        favoriteTools = [ ];
        cspConsents = { };
        toolConnections = { };
        toolSecondaryConnections = { };
        connectionsSort = "last-used";
        restoreSessionOnStartup = true;
        installId = "37e6a270-227d-48e6-ab31-2736ae4982b6";
      });
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
