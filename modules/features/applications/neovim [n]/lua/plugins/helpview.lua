---@type zpack.Spec
return {
    "OXY2DEV/helpview.nvim",
    lazy = true,
    ft = "help",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    ---@type helpview.config
    opts = {
        preview = {
            icon_provider = "devicons",
        },
    },
}
