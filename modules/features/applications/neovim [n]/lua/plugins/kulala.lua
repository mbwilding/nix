-- Postman

---@type zpack.Spec
return {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest", "javascript", "lua" },
    ---@type KulalaDefaultConfig
    opts = {
        global_keymaps = true,
        global_keymaps_prefix = "<leader>h",
        kulala_keymaps_prefix = "",
    },
}
