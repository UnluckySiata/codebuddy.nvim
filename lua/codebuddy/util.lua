local warn = vim.log.levels.WARN
local error = vim.log.levels.ERROR
local info = vim.log.levels.INFO

local M = {}
local log = {
    messages = {
        missing = "Missing configuration for filetype .%s",
        no_run = "Running method for .%s files not specified",
        no_comp = "Compilation method for .%s files not specified",
    },
    importance = {
        missing = error,
        no_run = error,
        no_comp = error,
    },
}

function M.notify(type, ft)
    local message = string.format(log.messages[type], ft)
    vim.notify(message, log.importance[type], { title = "codebuddy.nvim" })
end

return M
