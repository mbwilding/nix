---@type zpack.Spec
return {
    "folke/zen-mode.nvim",
    lazy = true,
    keys = {
        {
            "<leader>z",
            "<CMD>ZenMode<CR>",
            desc = "Zen-Mode: Toggle",
        },
    },
    ---@type ZenOptions
    opts = {
        window = {
            backdrop = 0.95,
            width = 0.60,
            height = 1,
            options = {
                signcolumn = "no",
                number = false,
                relativenumber = false,
                cursorline = false,
                cursorcolumn = false,
                foldcolumn = "0",
                list = false,
            },
        },
        plugins = {
            options = {
                enabled = true,
                ruler = false,
                showcmd = false,
                laststatus = 0,
            },
            twilight = { enabled = true },
            gitsigns = { enabled = false },
            tmux = { enabled = false },
        },
        ---@diagnostic disable-next-line: unused-local
        on_open = function(win) end,
        on_close = function() end,
    },
}
