
local util = require("codebuddy.util")
local terminal = require("codebuddy.terminal")

local augroup = vim.api.nvim_create_augroup("codebuddy", { clear = true })

---@alias Commands table<string, string>

---@class Options
---@field actions Action[]
---@field commands Commands[]
---@field local_cfg_file? string
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

    ---@type string
    _local_cfg_file = ".actions.lua",

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

    if opts.local_cfg_file then
        self._local_cfg_file = opts.local_cfg_file
    end

    -- check for a module with local configuration
    local local_config = vim.fs.find(self._local_cfg_file, {
        upward = true,
        stop = vim.loop.os_homedir(),
    })

    local error
    local file = local_config[1]  -- first matching path or nil

    if file then
        local cfg = dofile(file)
        if not cfg then
            error = "Reading configuration from" .. file .. " failed - lua module is empty"
            vim.notify(error, vim.log.levels.ERROR, { title = "codebuddy.nvim" })
            return
        end

        if cfg.commands then
            self._cmd_config = vim.tbl_deep_extend("force", self._cmd_config, cfg.commands)
        end
        if cfg.actions then
            for i, a in pairs(cfg.actions) do
                if type(a) ~= "table" or type(a.name) ~= "string" then
                    error = "Reading configuration from " .. file .. " failed - invalid action on index " .. i
                    vim.notify(error, vim.log.levels.ERROR, { title = "codebuddy.nvim" })
                    return
                end
            end
            self:__generate_actions(cfg.actions)
        end
    end
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
