local l = require("codebuddy.languages")
local util = require("codebuddy.util")

local function sp()
    vim.api.nvim_command("sp")
end
local function vsp()
    vim.api.nvim_command("vsp")
end

local augroup = vim.api.nvim_create_augroup("codebuddy", { clear = true })
local shell = os.getenv("SHELL") or "/bin/bash"
local term_pattern = "*" .. shell .. "*"

local M = {
    _opts = {
        term = {
            insert = true,
            num = false,
        },
    },
}


function M:__update(lang, file, ext)
    self._ext = ext
    self._curr_file = file
    self._lang = lang

    -- catch unsupported case
    if lang == nil then
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

    local cfg = l.commands[lang]

    if not cfg then return end
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

function M.setup(opts)
    opts = opts or {}

    if opts.commands then
        for k, v in pairs(opts.commands) do
            l["commands"][k] = v
        end

        opts.commands = nil
    end

    if opts.ext_match then
        for k, v in pairs(opts.ext_match) do
            l["ext_match"][k] = v
        end

        opts.commands = nil
    end

    for k, v in pairs(opts) do
        M._opts[k] = v
    end
    opts = M._opts

    if opts.term.insert then
        vim.api.nvim_create_autocmd({ "TermOpen" }, {
            pattern = { term_pattern },
            group = augroup,
            command = "startinsert",
        })
    end
    if not opts.term.num then
        vim.api.nvim_create_autocmd({ "TermOpen" }, {
            pattern = { term_pattern },
            group = augroup,
            command = "setlocal nonumber norelativenumber"
        })
    end
end

local function template_run(before, get_args)
    if not M._run then
        util.notify("no_run", M._ext)
        return
    end

    if before then
        before()
    end

    local args = ""
    if get_args then
        args = " " .. vim.fn.input("args: ")
    end

    local to_execute = M._run .. args

    vim.cmd("enew")
    if not M._opts.term.num then
        vim.cmd("setlocal nonumber norelativenumber")
    end
    if M._opts.term.insert then
        vim.cmd("startinsert")
    end
    vim.fn.termopen(to_execute, {
        on_exit = function()
        end
    })
end

function M.run()
    template_run(nil, false)
end

function M.run_args()
    template_run(nil, true)
end

function M.run_vsplit()
    template_run(vsp, false)
end

function M.run_vsplit_args()
    template_run(vsp, true)
end

function M.run_split()
    template_run(sp, false)
end

function M.run_split_args()
    template_run(sp, true)
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
        vim.cmd("enew")
        if not M._opts.term.num then
            vim.cmd("setlocal nonumber norelativenumber")
        end
        if M._opts.term.insert then
            vim.cmd("startinsert")
        end
        vim.fn.termopen(to_execute, {
            on_exit = function()
            end
        })
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
        M:__update(l.ext_match[ext], file, ext)
    end
})

return M
