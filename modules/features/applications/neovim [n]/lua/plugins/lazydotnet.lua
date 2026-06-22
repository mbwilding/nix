---@type zpack.Spec
return {
    "ckob/lazydotnet.nvim",
    cmd = "LazyDotnet",
    lazy = true,
    keys = {
        {
            "<leader>ld",
            "<CMD>LazyDotnet<CR>",
            desc = "LazyDotnet",
            mode = { "n", "t" },
        },
    },
    opts = {
        window = {
            width_ratio = 1.0,
            height_ratio = 1.0,
            border = "none", -- "none" | "single" | "double" | "rounded" | "solid" | "shadow"
        },
    },
}
