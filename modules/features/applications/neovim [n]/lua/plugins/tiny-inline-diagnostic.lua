vim.diagnostic.config({ virtual_text = false })

---@type zpack.Spec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    keys = {
        {
            "<leader>it",
            function()
                require("tiny-inline-diagnostic").toggle()
            end,
            desc = "Tiny Diag: Toggle",
        },
    },
    ---@type PluginConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        preset = "powerline", -- classic, minimal, powerline, ghost, simple, nonerdfont, amongus
        throttle = 0,         -- 20
        softwrap = 30,        -- min number of chars before wrap
        options = {
            multilines = {
                enabled = true,
                trim_whitespaces = true,
            },
            add_messages = {
                display_count = true,
            },
            show_source = {
                enabled = true,
            },
        },
    },
}
