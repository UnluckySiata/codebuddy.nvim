local _l = require("codebuddy.languages")
_l.setup()

local function __sp()
    vim.api.nvim_command("sp")
end
local function __vsp()
    vim.api.nvim_command("vsp")
end

local _augroup = vim.api.nvim_create_augroup("codebuddy", { clear = true })

local M = {
    _opts = {
        term = {
            insert = true,
            num = false,
        },
    },
}

function M:__update(lang, file)
    if not _l.languages[lang] then return end
    self._lang = lang
    self._curr_file = file
    self._cmd = _l.languages[lang].commands
    self._interpreted = _l.languages[lang].interpreted
    self._output_dir = _l.languages[lang].out_dir
    self._use_build_system = _l.languages[lang].use_build_system
end

function M.setup(opts)
    opts = opts or M._opts
    M._opts = opts
    if opts.term.insert then
        vim.api.nvim_create_autocmd({"TermOpen"}, {
            pattern = {"*"},
            group = _augroup,
            command = "startinsert",
        })
    end
    if not opts.term.num then
        vim.api.nvim_create_autocmd({"TermOpen"}, {
            pattern = {"*"},
            group = _augroup,
            command = "setlocal nonumber norelativenumber"
        })
    end
end

function M.__template_run(__before, _get_args)
    if __before then
        __before()
    end

    local args = ""
    if _get_args then
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
    vim.fn.termopen(to_execute, {
        on_exit = function ()
        end
    })
end

function M.run()
    M.__template_run(nil, false)
end

function M.run_args()
    M.__template_run(nil, true)
end

function M.run_vsplit()
    M.__template_run(__vsp, false)
end

function M.run_vsplit_args()
    M.__template_run(__vsp, true)
end

function M.run_split()
    M.__template_run(__sp, false)
end

function M.run_split_args()
    M.__template_run(__sp, true)
end

function M.__template_compile(_silent, _get_args)
    if not M._cmd.compile then
        print("No compilation method specified")
        return
    end
    local args = ""
    if _get_args then
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

    if _silent then
        vim.fn.system(to_execute)
    else
        vim.cmd("enew")
        vim.fn.termopen(to_execute, {
            on_exit = function ()
            end
        })
    end
end

function M.compile(silent, get_args)
    silent = silent or false
    get_args = get_args or false
    M.__template_compile(silent, get_args)
end


vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
    pattern = {"*.*"},
    group = _augroup,
    callback = function(args)
        local ext = string.match(args.file, "%.(%w+)")
        local file = vim.fn.expand("%")
        M:__update(_l.ext_match[ext], file)
    end
})

return M
