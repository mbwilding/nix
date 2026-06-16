{ ... }:

{
  flake.modules.homeManager.vscode =
    { pkgs, lib, ... }:

    let
      themeJson = builtins.toJSON {
        name = "Gronk";
        type = "dark";
        colors = {
          "editor.background" = "#000000";
          "editor.foreground" = "#bdbdbd";
          "editorLineNumber.foreground" = "#404040";
          "editorLineNumber.activeForeground" = "#787878";
          "editor.selectionBackground" = "#202020";
          "editor.lineHighlightBackground" = "#00000000";
          "editor.lineHighlightBorder" = "#00000000";
          "editorCursor.foreground" = "#bdbdbd";
          "editorInlayHint.background" = "#00000000";
          "editorInlayHint.foreground" = "#4f5258";
          "editorWidget.background" = "#101010";
          "editorWidget.border" = "#202020";
          "editorSuggestWidget.background" = "#101010";
          "editorSuggestWidget.border" = "#202020";
          "editorSuggestWidget.selectedBackground" = "#202020";
          "editorHoverWidget.background" = "#101010";
          "editorHoverWidget.border" = "#202020";
          "sideBar.background" = "#101010";
          "sideBar.foreground" = "#bdbdbd";
          "sideBarSectionHeader.background" = "#101010";
          "sideBarSectionHeader.foreground" = "#bdbdbd";
          "activityBar.background" = "#000000";
          "activityBar.foreground" = "#bdbdbd";
          "activityBar.inactiveForeground" = "#404040";
          "activityBarBadge.background" = "#4eade5";
          "activityBarBadge.foreground" = "#000000";
          "titleBar.activeBackground" = "#000000";
          "titleBar.activeForeground" = "#bdbdbd";
          "titleBar.inactiveBackground" = "#000000";
          "titleBar.inactiveForeground" = "#787878";
          "statusBar.background" = "#000000";
          "statusBar.foreground" = "#bdbdbd";
          "statusBar.noFolderBackground" = "#000000";
          "statusBarItem.hoverBackground" = "#202020";
          "statusBarItem.remoteBackground" = "#4eade5";
          "statusBarItem.remoteForeground" = "#000000";
          "tab.activeBackground" = "#101010";
          "tab.inactiveBackground" = "#000000";
          "tab.activeForeground" = "#bdbdbd";
          "tab.inactiveForeground" = "#787878";
          "tab.border" = "#000000";
          "tab.activeBorderTop" = "#4eade5";
          "editorGroupHeader.tabsBackground" = "#000000";
          "panel.background" = "#101010";
          "panel.border" = "#202020";
          "panelTitle.activeForeground" = "#bdbdbd";
          "panelTitle.activeBorder" = "#4eade5";
          "panelTitle.inactiveForeground" = "#787878";
          "terminal.background" = "#000000";
          "terminal.foreground" = "#bdbdbd";
          "terminalCursor.foreground" = "#bdbdbd";
          "input.background" = "#101010";
          "input.border" = "#202020";
          "input.foreground" = "#bdbdbd";
          "input.placeholderForeground" = "#787878";
          "dropdown.background" = "#101010";
          "dropdown.border" = "#202020";
          "dropdown.foreground" = "#bdbdbd";
          "button.background" = "#4eade5";
          "button.foreground" = "#000000";
          "button.hoverBackground" = "#6c95eb";
          "list.activeSelectionBackground" = "#202020";
          "list.activeSelectionForeground" = "#bdbdbd";
          "list.hoverBackground" = "#101010";
          "list.focusBackground" = "#202020";
          "list.inactiveSelectionBackground" = "#101010";
          "scrollbarSlider.background" = "#20202080";
          "scrollbarSlider.hoverBackground" = "#40404080";
          "scrollbarSlider.activeBackground" = "#60606080";
          "editorError.foreground" = "#ff4747";
          "editorWarning.foreground" = "#ffb083";
          "editorInfo.foreground" = "#4eade5";
          "editorHint.foreground" = "#66c3cc";
          "gitDecoration.addedResourceForeground" = "#39cc8f";
          "gitDecoration.modifiedResourceForeground" = "#4eade5";
          "gitDecoration.deletedResourceForeground" = "#ff4747";
          "gitDecoration.untrackedResourceForeground" = "#39cc8f";
          "gitDecoration.ignoredResourceForeground" = "#404040";
          "focusBorder" = "#202020";
          "contrastBorder" = "#00000000";
          "widget.shadow" = "#00000080";
          "badge.background" = "#4eade5";
          "badge.foreground" = "#000000";
          "progressBar.background" = "#4eade5";
          "notificationCenterHeader.background" = "#101010";
          "notifications.background" = "#101010";
          "notifications.border" = "#202020";
          "quickInput.background" = "#101010";
          "quickInputList.focusBackground" = "#202020";
          "pickerGroup.border" = "#202020";
          "pickerGroup.foreground" = "#787878";
          "menu.background" = "#101010";
          "menu.foreground" = "#bdbdbd";
          "menu.selectionBackground" = "#202020";
          "menu.selectionForeground" = "#bdbdbd";
          "menu.separatorBackground" = "#202020";
          "menubar.selectionBackground" = "#202020";
          "menubar.selectionForeground" = "#bdbdbd";
        };
        tokenColors = [
          # Comment -> c.comment #85c46c
          { scope = ["comment" "punctuation.definition.comment" "string.quoted.docstring"]; settings = { foreground = "#85c46c"; }; }

          # String -> c.string #c9a26d
          { scope = ["string" "string.quoted" "string.template" "string.interpolated"]; settings = { foreground = "#c9a26d"; }; }

          # Escape -> c.escape #ed94c0 (same as attribute/number)
          { scope = ["constant.character.escape" "constant.other.placeholder" "string.regexp"]; settings = { foreground = "#ed94c0"; }; }

          # Constant -> c.constant #83f1ff
          { scope = ["constant" "constant.language" "support.constant" "variable.other.constant"]; settings = { foreground = "#83f1ff"; }; }

          # Number -> c.number #ed94c0
          { scope = ["constant.numeric"]; settings = { foreground = "#ed94c0"; }; }

          # Keyword -> c.keyword #6c95eb
          { scope = ["keyword" "keyword.control" "keyword.operator.new" "storage.type" "keyword.declaration"]; settings = { foreground = "#6c95eb"; }; }

          # storage.modifier (mut/ref/etc) -> c.keyword + underline per @lsp.mod.mutable
          { scope = ["storage.modifier"]; settings = { foreground = "#6c95eb"; fontStyle = "underline"; }; }

          # Operator -> c.operator #a4a4a4
          { scope = ["keyword.operator" "punctuation.separator" "punctuation.terminator" "punctuation.accessor"]; settings = { foreground = "#a4a4a4"; }; }

          # Delimiter/punctuation -> c.operator #a4a4a4
          { scope = ["punctuation" "punctuation.definition" "punctuation.section" "meta.brace"]; settings = { foreground = "#a4a4a4"; }; }

          # Function/Method -> c.method #39cc8f
          { scope = ["entity.name.function" "support.function" "meta.function-call.generic" "entity.name.function.member"]; settings = { foreground = "#39cc8f"; }; }

          # Macro -> c.macro #4eade5
          { scope = ["meta.preprocessor" "entity.name.function.preprocessor" "entity.name.function.macro" "support.function.macro" "keyword.control.import" "keyword.other.use"]; settings = { foreground = "#4eade5"; }; }

          # Type/Struct/Class -> c.struct #c191ff
          { scope = ["entity.name.type" "entity.name.class" "support.class" "storage.type.class" "entity.name.type.class" "entity.name.type.struct"]; settings = { foreground = "#c191ff"; }; }

          # Enum -> c.enum #e2bfff
          { scope = ["entity.name.type.enum"]; settings = { foreground = "#e2bfff"; }; }

          # Interface -> c.interface #9591ff
          { scope = ["entity.name.type.interface" "entity.name.type.trait"]; settings = { foreground = "#9591ff"; }; }

          # Namespace -> c.namespace #ffb083
          { scope = ["entity.name.namespace" "entity.name.module" "storage.modifier.namespace"]; settings = { foreground = "#ffb083"; }; }

          # Module -> c.module #ffc794
          { scope = ["support.module" "entity.name.type.module"]; settings = { foreground = "#ffc794"; }; }

          # Variable -> c.variable #edeecf
          { scope = ["variable" "variable.other" "variable.other.readwrite"]; settings = { foreground = "#edeecf"; }; }

          # Variable.member / property -> c.member #91c2ff
          { scope = ["variable.other.member" "variable.other.property" "support.variable.property" "entity.name.variable.field"]; settings = { foreground = "#91c2ff"; }; }

          # Attribute/decorator -> c.attribute #ed94c0
          { scope = ["entity.other.attribute-name" "meta.attribute" "storage.type.annotation" "punctuation.definition.annotation"]; settings = { foreground = "#ed94c0"; }; }

          # Tag (HTML/JSX) -> c.keyword #6c95eb
          { scope = ["entity.name.tag" "meta.tag.sgml"]; settings = { foreground = "#6c95eb"; }; }

          # Deprecated/redundant -> c.redundant #787878
          { scope = ["invalid.deprecated" "comment.unused"]; settings = { foreground = "#787878"; }; }

          # Parameter -> c.variable #edeecf (italic like gronk's @lsp.typemod.parameter)
          { scope = ["variable.parameter" "entity.name.variable.parameter"]; settings = { foreground = "#edeecf"; fontStyle = "italic"; }; }
        ];
      };

      packageJson = builtins.toJSON {
        name = "gronk-theme";
        displayName = "Gronk";
        description = "Gronk dark theme for VSCode";
        version = "1.0.0";
        publisher = "mbwilding";
        engines.vscode = "^1.0.0";
        categories = ["Themes"];
        contributes.themes = [{
          label = "Gronk";
          uiTheme = "vs-dark";
          path = "./themes/gronk-color-theme.json";
        }];
      };

      gronkTheme = pkgs.vscode-utils.buildVscodeExtension {
        pname = "gronk-theme";
        vscodeExtPublisher = "mbwilding";
        vscodeExtName = "gronk-theme";
        vscodeExtUniqueId = "mbwilding.gronk-theme";
        version = "1.0.0";
        src = pkgs.runCommand "gronk-theme-src" {} ''
          mkdir -p $out/themes
          echo '${packageJson}' > $out/package.json
          echo '${themeJson}' > $out/themes/gronk-color-theme.json
        '';
        dontUnpack = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/vscode/extensions/mbwilding.gronk-theme
          cp -r $src/. $out/share/vscode/extensions/mbwilding.gronk-theme/
          runHook postInstall
        '';
      };
    in
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;

        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            github.copilot
            github.copilot-chat
            pkief.material-icon-theme
            eamodio.gitlens
            usernamehw.errorlens
            vscodevim.vim
          ] ++ [ gronkTheme ];

          userSettings = {
            # Theme
            "workbench.colorTheme" = "Gronk";
            "workbench.iconTheme" = "material-icon-theme";
            "workbench.startupEditor" = "none";

            # Editor
            "editor.fontFamily" = "'NeoSpleen Nerd Font', monospace";
            "editor.fontSize" = 14;
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

            # Copilot
            "github.copilot.enable"."*" = true;

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

            # Hide sidebar on startup
            "workbench.editor.sideBarVisible" = false;

            # Hide AI / chat
            "chat.commandCenter.enabled" = false;
            "github.copilot.chat.welcomeMessage" = "never";
            "workbench.secondarySideBar.visible" = false;

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

            # VSCodeVim
            "vim.leader" = "<space>";
            "vim.useSystemClipboard" = false;
            "vim.useCtrlKeys" = true;
            "vim.hlsearch" = true;
            "vim.incsearch" = true;
            "vim.ignorecase" = true;
            "vim.smartcase" = true;

            # Hand back keys VSCode handles better
            "vim.handleKeys" = {
              "<C-c>" = false;
              "<C-v>" = false;
              "<C-z>" = false;
              "<C-s>" = false;
              "<C-f>" = false;
              "<C-w>" = false;
            };

            "vim.normalModeKeyBindingsNonRecursive" = [
              # ; -> / (search)
              { before = [";"]; after = ["/"];}

              # Esc -> clear search highlight
              { before = ["<Esc>"]; commands = [":nohl"]; }

              # U -> redo
              { before = ["U"]; after = ["<C-r>"]; }

              # x -> black hole delete
              { before = ["x"]; after = ["\"" "_" "x"]; }

              # Window focus
              { before = ["<C-h>"]; commands = ["workbench.action.focusLeftGroup"]; }
              { before = ["<C-j>"]; commands = ["workbench.action.focusBelowGroup"]; }
              { before = ["<C-k>"]; commands = ["workbench.action.focusAboveGroup"]; }
              { before = ["<C-l>"]; commands = ["workbench.action.focusRightGroup"]; }

              # Diagnostics navigation
              { before = ["[" "d"]; commands = ["editor.action.marker.prevInFiles"]; }
              { before = ["]" "d"]; commands = ["editor.action.marker.nextInFiles"]; }

              # yd -> duplicate line
              { before = ["y" "d"]; after = ["y" "y" "p"]; }

              # <leader>p -> paste from clipboard
              { before = ["<leader>" "p"]; after = ["\"" "+" "p"]; }
              { before = ["<leader>" "P"]; after = ["\"" "+" "P"]; }

              # <leader>y -> yank to clipboard
              { before = ["<leader>" "y"]; after = ["\"" "+" "y"]; }
              { before = ["<leader>" "y" "y"]; after = ["\"" "+" "y" "y"]; }

              # <leader>q -> close tab
              { before = ["<leader>" "q"]; commands = ["workbench.action.closeActiveEditor"]; }

              # <leader>f -> format
              { before = ["<leader>" "f"]; commands = ["editor.action.formatDocument"]; }

              # <leader>rn -> rename symbol
              { before = ["<leader>" "r" "n"]; commands = ["editor.action.rename"]; }

              # <leader>k -> show diagnostics hover
              { before = ["<leader>" "k"]; commands = ["editor.action.showHover"]; }

              # <leader>id -> toggle diagnostics
              { before = ["<leader>" "i" "d"]; commands = ["workbench.actions.view.problems"]; }

              # <leader>ir -> toggle relative line numbers
              { before = ["<leader>" "i" "r"]; commands = ["toggleRelativeLineNumbers"]; }
            ];

            "vim.visualModeKeyBindingsNonRecursive" = [
              # s -> sort selection
              { before = ["s"]; commands = ["editor.action.sortLinesAscending"]; }

              # <leader>p -> paste from clipboard
              { before = ["<leader>" "p"]; after = ["\"" "+" "p"]; }
              { before = ["<leader>" "P"]; after = ["\"" "+" "P"]; }

              # <leader>y -> yank to clipboard
              { before = ["<leader>" "y"]; after = ["\"" "+" "y"]; }

              # <leader>rn -> replace all matching selected
              { before = ["<leader>" "r" "n"]; commands = ["editor.action.startFindReplaceAction"]; }

              # Repeatable indent/outdent
              { before = [">"]; commands = ["editor.action.indentLines"]; }
              { before = ["<"]; commands = ["editor.action.outdentLines"]; }
            ];

            "vim.insertModeKeyBindings" = [
              # Ctrl+hjkl navigation in insert mode
              { before = ["<C-k>"]; after = ["<Up>"]; }
              { before = ["<C-j>"]; after = ["<Down>"]; }
              { before = ["<C-h>"]; after = ["<Left>"]; }
              { before = ["<C-l>"]; after = ["<Right>"]; }
            ];
          };
        };
      };

      # Patch any new VSCode workspace state.vscdb to hide sidebars by default
      systemd.user.services.vscode-workspace-patcher = {
        Unit = {
          Description = "Patch new VSCode workspace databases to hide sidebars";
        };
        Service = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.writeShellScript "vscode-workspace-patcher" ''
                STORAGE="$HOME/.config/Code/User/workspaceStorage"
                [ -d "$STORAGE" ] || exit 0
                for db in "$STORAGE"/*/state.vscdb; do
                  [ -f "$db" ] || continue
                  ${pkgs.sqlite}/bin/sqlite3 "$db" "
                    INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('workbench.sideBar.hidden', 'true');
                    INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('workbench.auxiliaryBar.hidden', 'true');
                    INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('workbench.panel.hidden', 'true');
                    INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('workbench.statusBar.hidden', 'true');
                    INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('workbench.activityBar.hidden', 'true');
                  " 2>/dev/null || true
                done
              '';
            in
            "${script}";
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.paths.vscode-workspace-patcher = {
        Unit = {
          Description = "Watch for new VSCode workspace databases";
        };
        Path = {
          PathChanged = "%h/.config/Code/User/workspaceStorage";
          MakeDirectory = true;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
