---@type zpack.Spec
return {
    "Wansmer/treesj",
    lazy = true,
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    keys = {
        {
            "<leader>j",
            "<CMD>TSJToggle<CR>",
            desc = "TreeSJ: Toggle",
        },
    },
    ---@type { use_default_keymaps: boolean, check_syntax_error: boolean, max_join_length: number, cursor_behavior: 'hold'|'start'|'end', notify: boolean, langs: table, dot_repeat: boolean, on_error: nil|function }
    opts = {
        use_default_keymaps = false,
    },
}
