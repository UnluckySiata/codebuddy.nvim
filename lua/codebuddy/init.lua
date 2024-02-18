
local util = require("codebuddy.util")
local terminal = require("codebuddy.terminal")

local augroup = vim.api.nvim_create_augroup("codebuddy", { clear = true })

---@alias Commands table<string, string>

---@class Options
---@field actions Action[]
---@field commands Commands[]
---@field term? TerminalOptions

---@class Keybind
---@field mode string | table<string>
---@field binding string
---@field opts? table 

---@class Action
---@field name string
---@field ask_for_args? boolean
---@field keybind? Keybind

local M = {
    ---@type Commands[]
    _cmd_config = {},

    ---@type Commands
    _commands = {},

    ---@type function[]
    actions = {},
}


function M:__update(file, ext)
    self._ext = ext
    self._curr_file = file

    local cfg = self._cmd_config[ext]

    -- catch unsupported case
    if cfg == nil then
        -- clear action config
        self._commands = {}

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

    for name, cmd in pairs(cfg) do
        prepared = string.gsub(cmd, "{file}", self._filename)
        prepared = string.gsub(prepared, "{relative_dir}", self._relative_dir)
        prepared = string.gsub(prepared, "{file_path}", self._file_path)
        prepared = string.gsub(prepared, "{ext}", self._ext)
        self._commands[name] = prepared
    end
end


---@param actions Action[]
function M:__generate_actions(actions)

    for _, a in pairs(actions) do
         local f = function ()
            if M._commands[a.name] == nil then
                local error = string.format("No \"%s\" action for a .%s file", a.name, self._ext)

                vim.notify(error, vim.log.levels.ERROR, { title = "codebuddy.nvim" })
                return
            end

            local args = ""
            if a.ask_for_args then
                args = " " .. vim.fn.input("args: ")
            end

            terminal:execute(self._commands[a.name] .. args)
        end

        self.actions[a.name] = f

        if a.keybind then
            local opts = a.keybind.opts or {}
            vim.keymap.set(a.keybind.mode, a.keybind.binding, f, opts)
        end
    end
end


---@param opts Options
function M:setup(opts)
    self._cmd_config = vim.tbl_deep_extend("force", self._cmd_config, opts.commands)

    self:__generate_actions(opts.actions)
    terminal:setup(opts.term)
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
