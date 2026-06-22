---@type zpack.Spec
return {
    "ckob/lazydotnet.nvim",
    cmd = "LazyDotnet",
    keys = {
        {
            "<leader>ld",
            "<CMD>LazyDotnet<CR>",
            desc = "LazyDotnet",
            mode = { "n", "t" },
        },
    },
}
