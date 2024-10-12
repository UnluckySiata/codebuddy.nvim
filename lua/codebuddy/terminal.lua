
local height_scale = 0.5
local width_scale = 0.5
local lines = vim.o.lines - vim.o.cmdheight
local columns = vim.o.columns

---@class TerminalOptions
---@field relative? "editor" | "win" | "cursor" | "mouse"
---@field height_scale? float
---@field width_scale? float
---@field row? integer
---@field col? integer
---@field border? "none" | "single" | "double" | "rounded" | "solid" | "shadow"
---@field start_insert? boolean
---@field no_number? boolean

local Terminal = {
    opts = {
        relative = "editor",
        height = 0,
        width = 0,
        row = 0,
        col = 0,
        border = "rounded",
        start_insert = false,
        no_number = false,
    }
}

---@param opts? TerminalOptions
function Terminal:setup(opts)
    opts = opts or {}
    height_scale = opts.height_scale or height_scale
    width_scale = opts.width_scale or width_scale

    local height = math.floor(height_scale * lines)
    local width = math.floor(width_scale * columns)
    local row = math.floor((lines - height) / 2)
    local col = math.floor((columns - width) / 2)

    self.opts.height = height
    self.opts.width = width
    self.opts.row = row
    self.opts.col = col

    self.opts = vim.tbl_extend("force", self.opts, opts)
end

---@param cmd string
function Terminal:execute(cmd)
    local opts = self.opts
    local b = vim.api.nvim_create_buf(false, false)

    if b == 0 then
        vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR, { title = "codebuddy.nvim" })
    end

    local w = vim.api.nvim_open_win(b, true, {
        relative = opts.relative,
        row = opts.row,
        col = opts.col,
        width = opts.width,
        height = opts.height,
        border = opts.border,
        title = "Codebuddy",
        noautocmd = true,
    })

    if w == 0 then
        vim.notify("Failed to create terminal window", vim.log.levels.ERROR, { title = "codebuddy.nvim" })
    end

    vim.api.nvim_buf_call(b, function ()
        vim.fn.termopen(cmd)

        if self.opts.no_number then
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
        end

        if self.opts.start_insert then
            vim.cmd("startinsert")
        end
    end)
end

return Terminal
