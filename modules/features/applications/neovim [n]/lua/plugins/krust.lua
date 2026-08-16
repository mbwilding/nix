---@type zpack.Spec
return {
    "alexpasmantier/krust.nvim",
    ft = "rust",
    ---@type KrustConfig
    opts = {
        keymap = "<leader>k",
        float_win = {
            border = "none", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
            auto_focus = false,
        },
    },
}
