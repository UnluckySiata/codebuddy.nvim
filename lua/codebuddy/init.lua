local l = require("codebuddy.languages")
local util = require("codebuddy.util")
l.setup()

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

    if not l.languages[lang] then return end
    self._cmd = l.languages[lang].commands
    self._interpreted = l.languages[lang].interpreted
    self._output_dir = l.languages[lang].out_dir
    self._use_build_system = l.languages[lang].use_build_system
end

function M.setup(opts)
    opts = opts or M._opts
    M._opts = opts
    if opts.term.insert then
        vim.api.nvim_create_autocmd({"TermOpen"}, {
            pattern = {term_pattern},
            group = augroup,
            command = "startinsert",
        })
    end
    if not opts.term.num then
        vim.api.nvim_create_autocmd({"TermOpen"}, {
            pattern = {term_pattern},
            group = augroup,
            command = "setlocal nonumber norelativenumber"
        })
    end
end

local function template_run(before, get_args)
    if not M._cmd then
        util.log("missing", M._ext)
        return
    end

    if not M._cmd.run then
        util.log("no_run", M._ext)
        return
    end

    if before then
        before()
    end

    local args = ""
    if get_args then
        args = " " .. vim.fn.input("args: ")
    end

    vim.cmd("enew")

    local to_execute
    if M._interpreted then
        to_execute = M._cmd.run .. M._curr_file .. args
    else -- compiled
        if M._use_build_system then
            to_execute = M._cmd.run .. args
        else
            local cwd = vim.fn.getcwd()
            local outdir = cwd .. "/" .. M._output_dir
            local exists = vim.fn.isdirectory(outdir)
            if exists == 0 then
                vim.fn.mkdir(outdir)
            end
            to_execute = string.format("%s%s && %s%s", M._cmd.compile, M._curr_file, M._cmd.run, args)
        end
    end
    if not M._opts.term.num then
        vim.cmd("setlocal nonumber norelativenumber")
    end
    if M._opts.term.insert then
        vim.cmd("startinsert")
    end
    vim.fn.termopen(to_execute, {
        on_exit = function ()
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

local function template_compile(silent, get_args)
    if not M._cmd then
        util.log("missing", M._ext)
        return
    end

    if not M._cmd.compile then
        util.log("no_comp", M._ext)
        return
    end

    local args = ""
    if get_args then
        args = " " .. vim.fn.input("args: ")
    end
    local to_execute
    if M._use_build_system then
        to_execute = M._cmd.compile .. args
    else
        local cwd = vim.fn.getcwd()
        local outdir = cwd .. "/" .. M._output_dir
        local exists = vim.fn.isdirectory(outdir)
        if exists == 0 then
            vim.fn.mkdir(outdir)
        end
        to_execute = M._cmd.compile .. M._curr_file
    end

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
            on_exit = function ()
            end
        })
    end
end

function M.compile(silent, get_args)
    silent = silent or false
    get_args = get_args or false
    template_compile(silent, get_args)
end


vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
    pattern = {"*.*"},
    group = augroup,
    callback = function(args)
        local ext = string.match(args.file, "%.(%w+)$")
        local file = vim.fn.expand("%")
        M:__update(l.ext_match[ext], file, ext)
    end
})

return M
