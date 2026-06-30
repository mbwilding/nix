-- Postman

---@type zpack.Spec
return {
    "mistweaverco/kulala.nvim",
    event = { "SessionLoadPost", "VimLeavePre" },
    ft = { "http", "rest", "javascript", "lua" },
    ---@type KulalaDefaultConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        global_keymaps = true,
        global_keymaps_prefix = "<leader>h",
        kulala_keymaps_prefix = "",
    },
}
