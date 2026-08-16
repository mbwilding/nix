---@type zpack.Spec
return {
    "chrisgrieser/nvim-spider",
    lazy = false,
    keys = {
        { "w",  "<cmd>lua require('spider').motion('w')<CR>",  mode = { "n", "o", "x" } },
        { "e",  "<cmd>lua require('spider').motion('e')<CR>",  mode = { "n", "o", "x" } },
        { "b",  "<cmd>lua require('spider').motion('b')<CR>",  mode = { "n", "o", "x" } },
        { "ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } },
    },
    ---@type Spider.config
    opts = {
        skipInsignificantPunctuation = true,
        subwordMovement = false,
        consistentOperatorPending = false,
        customPatterns = {},
    },
}
