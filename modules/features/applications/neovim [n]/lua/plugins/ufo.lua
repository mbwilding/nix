vim.o.foldenable = true
-- vim.o.foldcolumn = "1"
vim.o.foldcolumn = "0"
vim.o.fillchars = "eob: ,fold: ,diff:/,foldopen:,foldsep: ,foldclose:"
vim.o.foldlevel = 99999999
vim.o.foldlevelstart = 99999999

---@type zpack.Spec
return {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    keys = {
        {
            "<leader>zA",
            function()
                require("ufo").openAllFolds()
            end,
            desc = "UFO Folds: Expand All",
        },
        {
            "<leader>zM",
            function()
                require("ufo").closeAllFolds()
            end,
            desc = "UFO Folds: Collapse All",
        },
    },
    ---@type UfoConfig
    opts = {
        -- Without this, ufo's default {'lsp','indent'} provider attaches to every
        -- buffer, including acwrite/custom-UI buffers (e.g. dotnet.nvim's solution
        -- tree) that manage their own manual folds — the two fought over fold state
        -- via the same TextChanged/BufWinEnter events, producing wrong fold ranges.
        provider_selector = function(_, filetype, buftype)
            if buftype == "acwrite" or filetype == "dotnet-sln" then
                return ""
            end
            return { "lsp", "indent" }
        end,
    },
}
