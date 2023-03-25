# Codebuddy
## Introduction
Codebuddy is a pluggin for executing common actions on your code based on the
current buffer. Realistically I don't expect anyone except myself to find it helpful,
but if you're interested you're more than welcome to use it as is or make it your own.
It utilizes vim's builtin terminal emulator for output
and interactivity. The plugin is intended for providing the ability 
to call frequently used actions like compiling and running code (more in the future..)
with a few keystrokes. The code is in development and in current form lacks
simple ways to configure language configuration without editing the source code
itself.

## Documentation
Currently non-existant :( but will come someday in the future.
The code is simple enough so that you should be able to tell what's going on.

## Features
- running and compiling code 
- multiple variants of bindable functions
- compile with output or silently
- execute commands in fullscreen/split/vsplit buffer that exits after it's done 
- can prompt for additional arguments withing neovim window
- and more to come :)

## But why?
There are already some code runners for neovim, but i wanted to make
something that is simple, configurable and easy to extend. Someday this plugin
will hopefully become something worth giving a change. It is
also a good opportunity for me to learn and experiment with neovim
plugin creation and it's fun to use something that you've written yourself.

## Installation
Currently the version you should install is on the main branch. Get it with
your favorite package manager. With packer the command is
```lua
use "unluckysiata/codebuddy"
```
## Configuration
For the time being there isn't a lot you can customize. In the setup function
you can specify a few options (but then you must provide a lua table with the same
structure as the default one) or just leave it as is. A simple configuration file
can look like this
```lua
local ok, cb = pcall(require, "codebuddy")
if not ok then return end

cb.setup()

vim.keymap.set("n", "<leader>rr", cb.run)
vim.keymap.set("n", "<leader>ra", cb.run_vsplit_args)
vim.keymap.set("n", "<leader>rv", cb.run_vsplit)
vim.keymap.set("n", "<leader>rs", cb.run_split)
vim.keymap.set("n", "<leader>rc", cb.compile)
```


