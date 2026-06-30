local function codecompanion_prompt(command_prefix)
    vim.ui.input({ prompt = "AI: " }, function(input)
        if input and input ~= "" then
            local prefix = command_prefix and (command_prefix .. " ") or ""
            vim.cmd("CodeCompanion " .. prefix .. input)
        end
    end)
end

-- local adapter = "copilot"
-- local model = "claude-sonnet-4-6"
local adapter = "llama-swap"
local model = "qwythos-9b-abliterated"

---@type zpack.Spec
return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "zbirenbaum/copilot.lua",
    },
    keys = {
        {
            "<leader>aia",
            mode = { "n", "v" },
            "<CMD>CodeCompanionActions<CR>",
            desc = "CodeCompanion: Actions",
        },
        {
            "<leader>aic",
            mode = { "n", "v" },
            "<CMD>CodeCompanionChat Toggle<CR>",
            desc = "CodeCompanion: Chat",
        },
        {
            "<leader>aii",
            mode = { "n" },
            function()
                codecompanion_prompt("#{buffer}")
            end,
            desc = "CodeCompanion: Buffer",
        },
        {
            "<leader>aii",
            mode = { "v" },
            function()
                codecompanion_prompt()
            end,
            desc = "CodeCompanion: Selection",
        },
    },
    opts = {
        adapters = {
            ["llama-swap"] = function()
                return require("codecompanion.adapters").extend("openai_compatible", {
                    name = "llama-swap",
                    formatted_name = "LlamaSwap",
                    schema = {
                        model = {
                            default = "qwythos-9b-abliterated",
                        },
                    },
                    env = {
                        url = "http://192.168.11.254:60000",
                    },
                })
            end,
        },
        strategies = {
            chat = {
                adapter = adapter,
                model = model,
            },
            inline = {
                adapter = adapter,
                model = model,
            },
            agent = {
                adapter = adapter,
                model = model,
            },
            cmd = {
                adapter = adapter,
                model = model,
            },
        },
    },
}
