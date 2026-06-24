vim.g.start_time = vim.uv.hrtime()

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.g.end_time = vim.uv.hrtime()
    end,
})

local config = vim.fn.stdpath("config")
local base = config .. "/lua/"

local pl_handle = vim.uv.fs_scandir(base .. "plugins-local")
if pl_handle then
    while true do
        local name, type = vim.uv.fs_scandir_next(pl_handle)
        if not name then break end
        if type == "directory" then
            vim.opt.rtp:prepend(base .. "plugins-local/" .. name)
            require(name)
        end
    end
end

local function autoload(dir)
    local path = dir and base .. dir or base
    local handle = vim.uv.fs_scandir(path)
    if not handle then return end
    while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if not name:match("^_") and name ~= "plugins" and name ~= "plugins-local" then
            if type == "directory" then
                autoload(dir and (dir .. "/" .. name) or name)
            else
                local mod = name:match("^(.+)%.lua$")
                if mod then
                    require(dir and (dir:gsub("/", ".") .. "." .. mod) or mod)
                end
            end
        end
    end
end

autoload()
