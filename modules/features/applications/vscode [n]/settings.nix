{ ... }:

{
  flake.modules.homeManager.vscode =
    { ... }:

    {
      programs.vscode.profiles.default.userSettings = {
        # Theme
        "workbench.colorTheme" = "Gronk";
        "workbench.startupEditor" = "none";

        # Editor
        "editor.fontFamily" = "'NeoSpleen Nerd Font', monospace";
        "editor.fontSize" = 12;
        "editor.tabSize" = 4;
        "editor.insertSpaces" = true;
        "editor.wordWrap" = "off";
        "editor.lineNumbers" = "on";
        "editor.rulers" = [ ];
        "editor.minimap.enabled" = false;
        "editor.scrollBeyondLastLine" = false;
        "editor.renderWhitespace" = "trailing";
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = false;
        "editor.inlayHints.enabled" = "on";
        "editor.suggest.preview" = true;
        "editor.formatOnSave" = true;

        # Terminal
        "terminal.integrated.fontFamily" = "'NeoSpleen Nerd Font'";

        # Explorer
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # Files
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.autoSave" = "off";

        # Misc
        "breadcrumbs.enabled" = false;
        "window.menuBarVisibility" = "toggle";
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";

        # Hide tabs (single buffer workflow)
        "workbench.editor.showTabs" = "single";
        "workbench.editor.enablePreview" = false;

        # Hide activity bar, status bar, sidebar by default
        "workbench.activityBar.location" = "hidden";
        "workbench.statusBar.visible" = false;
        "workbench.sideBar.location" = "right";

        # Hide AI / chat
        "chat.commandCenter.enabled" = false;

        # Zen mode as default -- hides everything except editor, persists across restarts
        "zenMode.restore" = true;
        "zenMode.fullScreen" = false;
        "zenMode.centerLayout" = false;
        "zenMode.hideActivityBar" = true;
        "zenMode.hideStatusBar" = true;
        "zenMode.hideLineNumbers" = false;
        "zenMode.showTabs" = "single";
        "zenMode.silentNotifications" = false;

        # Zen-like editor
        "editor.scrollbar.vertical" = "hidden";
        "editor.scrollbar.horizontal" = "hidden";
        "editor.overviewRulerBorder" = false;
        "editor.hideCursorInOverviewRuler" = true;
      };
    };
}
