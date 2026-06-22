---@type zpack.Spec
return {
    "folke/lazydev.nvim",
    ft = "lua",
    ---@type lazydev.Config
    opts = {
        integrations = {
            cmp = false,
            coq = false,
        },
        library = {
            {
                path = "${3rd}/luv/library",
                words = { "vim%.uv" },
            },
            {
                path = "zpack.nvim",
                words = { "zpack" },
            },
            {
                path = "snacks.nvim",
                words = { "Snacks" },
            },
            {
                path = "zen-mode.nvim",
                words = { "zen-mode.nvim" },
            },
            {
                path = "lazydev.nvim",
                words = { "lazydev.nvim" },
            },
        },
    },
}
