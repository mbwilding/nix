{ vscode-extensions }:

{
  extension = vscode-extensions.vscodevim.vim;

  settings = {
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

      # <leader><leader> -> file search (quick open)
      { before = ["<leader>" "<leader>"]; commands = ["workbench.action.quickOpen"]; }

      # <leader>e -> open file tree
      { before = ["<leader>" "e"]; commands = ["workbench.view.explorer"]; }

      # <leader>/ -> find in files
      { before = ["<leader>" "/"]; commands = ["workbench.action.findInFiles"]; }

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
}
