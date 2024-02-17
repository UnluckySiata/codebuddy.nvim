
local util = require("codebuddy.util")
local terminal = require("codebuddy.terminal")

local augroup = vim.api.nvim_create_augroup("codebuddy", { clear = true })

---@alias Commands table<string, string>[]

---@class Options
---@field commands Commands
---@field term? TerminalOptions

local M = {
    ---@type Commands
    _commands = {},
}


---@param opts Options
function M:setup(opts)
    self._commands = vim.tbl_deep_extend("force", self._commands, opts.commands)

    terminal:setup(opts.term)
end


function M:__update(file, ext)
    self._ext = ext
    self._curr_file = file

    local cfg = self._commands[ext]

    -- catch unsupported case
    if cfg == nil then
        -- clear action config
        self._build = nil
        self._run = nil

        -- clear fields available for substitution
        self._filename = nil
        self._relative_dir = nil
        self._file_path = nil
        return
    end

    self._filename = string.match(file, "([%w_-]+)." .. ext .. "$") or ""
    self._relative_dir = string.match(file, "(.-)/[^/]*$") or ""

    -- same as {relative_dir}/{file}.{ext}
    self._file_path = file

    local prepared

    if cfg.build then
        prepared = string.gsub(cfg.build, "{file}", self._filename)
        prepared = string.gsub(prepared, "{relative_dir}", self._relative_dir)
        prepared = string.gsub(prepared, "{file_path}", self._file_path)
        prepared = string.gsub(prepared, "{ext}", self._ext)
        self._build = prepared
    end

    prepared = string.gsub(cfg.run, "{file}", self._filename)
    prepared = string.gsub(prepared, "{relative_dir}", self._relative_dir)
    prepared = string.gsub(prepared, "{file_path}", self._file_path)
    prepared = string.gsub(prepared, "{ext}", self._ext)
    self._run = prepared
end


local function template_run(get_args)
    if not M._run then
        util.notify("no_run", M._ext)
        return
    end

    local args = ""
    if get_args then
        args = " " .. vim.fn.input("args: ")
    end

    terminal:execute(M._run .. args)
end

function M.run()
    template_run(false)
end

function M.run_args()
    template_run(true)
end


local function template_build(silent, get_args)
    if not M._build then
        util.notify("no_comp", M._ext)
        return
    end

    local args = ""
    if get_args then
        args = " " .. vim.fn.input("args: ")
    end

    local to_execute = M._build .. args
    if silent then
        vim.fn.system(to_execute)
    else
        terminal:execute(to_execute)
    end
end

function M.build(silent, get_args)
    silent = silent or false
    get_args = get_args or false
    template_build(silent, get_args)
end


vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = { "*" },
    group = augroup,
    callback = function(args)
        local ext = string.match(args.file, "%.([%w_-]+)$")
        local file = vim.fn.expand("%")
        M:__update(file, ext)
    end
})

return M
