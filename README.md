# codebuddy.nvim
This is basically my effort to learn plugin development for neovim.
Aside from that it is also a useful tool (for me) to execute
some common commands like compiling and running code.

## How it works?
User specifies actions with their keybindings, which are then
created automatically. Upon entering a file the configuration
for current file type is loaded and placeholders inside
each commands are substituted for appropriate file information.
Upon execution, an action takes the prepared command specified
for this action and executes it in a floating pseudo-terminal
window. The idea is simple and can be an alternative to
binding build scripts to use them inside neovim. If you
prefer to execute everything from outside the editor then
this is probably not for you.

## Documentation
Currently there is no vim manual file but everything you need
to know is here in the readme and in type annotations for
config options.

## Features
- defining custom actions with arbitrary names
- configuring each action per filetype
- local configuration file overwriting global options for a project

**Note:** For the latest changes checkout the *dev* branch

## Installation
Get it with your favorite package manager. Here's how to add the (most) stable
version using Packer
```lua
use {
    "unluckysiata/codebuddy",
    branch = "main"
}
```
## Configuration
There are two types of configuration - the global one that you set up like any other neovim
plugin and a local one that is dynamically loaded when you open a neovim instance inside
of a directory that can trace a config file (default = .actions.lua, which is searched for
by traversing directories up starting with working directory). The first type is
required while the second can be set on a per-project basis.

### Expandables
While defining commands you can include placeholders that will expand
upon entering a file.
Currently available ones are:
- {file} - file name without the extension 
- {ext} - extension
- {relative_dir} - relative directory of current file with respect to where you opened neovim from
- {file_path} - shortcut for {relative_dir}/{file}.ext

### Global config
Here is a sample file containing the plugin's configuration.
```lua
local ok, cb = pcall(require, "codebuddy")
if not ok then return end

-- this call is necessary for the plugin to work
cb:setup {
    -- define at least one action, (otherwise what's the point ;))
    actions = {
        { name = "run",   keybind = { mode = "n", binding = "<leader>rr" }, ask_for_args = true },
        { name = "build", keybind = { mode = "n", binding = "<leader>rc" } },
    },
    -- here define action behavior for filetypes
    commands = {
        c = {
            build = "gcc -Wall -g -o {file} {file_path}",
            run = "./{file}",
            none = "..."  -- no such action defined so this will be ignored
        },
        rs = {
            build = "cargo build",
            run = "cargo run",
        },
    },

    -- the name of file to search for local configuration
    -- if you're ok with the default then you don't need to specify this
    local_cfg_file = ".actions.lua",

    -- options for the terminal window displaying outputs
    -- all options apply only to the window managed by this plugin
    -- below are the defaults for every option - if you omit any, these will be used
    term = {
        relative = "editor"  -- same as in nvim_open_win,

        -- window scales with respect to editor size
        height_scale = 0.5, 
        width_scale = 0.5,

        -- beginning rows and columns of terminal window
        -- the default values will make it centered (best to omit those)
        row = math.floor((lines - height) / 2),
        col = math.floor((columns - width) / 2),

        border = "rounded",

        -- whether to enter insert mode inside the terminal window
        start_insert = false,  
        -- option for disabling the number line 
        no_number = false,
    },
}
```
**Note**: As you may have noticed, there are no calls to ```vim.keymap.set(...) ```.
This is to prevent diagnostics messages that you're binding to
a function that doesn't exist (because they are created during setup)
and to make the configuration more hands-off. You can still manually
bind them - consider the following example (assumes you defined a "test" action)
```lua

-- just manually bind the function (but why?)
vim.keymap.set("n", "<leader>rt", cb.actions.test)


-- or bind to a more complicated function
vim.keymap.set("n", "<leader>rt", function ()
    -- do something
    ...
    cb.actions.test()
end)
```


### Local config
The structure of local config is similar to the global one.
The file containing it must be a lua module, inside of which
you can specify additional actions and commands (**IMPORTANT**
the global config still applies, if any field defined in both
configs overlaps ex. a build actions for c files then the one
from local config will take precedence). Here is a sample local
config file
```lua

return {
    actions = {
        { name = "test", keybind = { mode = "n", binding = "<leader>rt" } }
    },
    commands = {
        rs = {
            build = "cargo build --release",
            run = "cargo run --release",
            test = "cargo test",
        }
    },
}
```

**Note**: Although i wrote some sanity checks for the local configuration
and for example defining "actions" as a number will log a custom error,
you can still make this crash. This is easier inside local configuration
since it isn't type checked (well, dynamically) like the arguments
for a setup call inside global config. Here is a local config that
will give a nasty error
```lua
return {
    actions = {
        -- well we specified a keybind field, but mode and binding are missing
        -- I could've written something to check for this but there's no point
        -- since you need to actively try to break things
        { name = "test", keybind = {} }
    },
}
```
