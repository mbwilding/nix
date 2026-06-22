---@type zpack.Spec
return {
    "FabijanZulj/blame.nvim",
    lazy = false,
    ---@type Config
    opts = {},
    keys = {
        { "<leader>ib", "<CMD>BlameToggle window<CR>", desc = "Git Blame" },
    },
}
