
local M = {
    languages = {
        erlang = {
            out_dir = "out",
            out_opt_c = "-o",
            out_opt_r = "-pa",
            commands = {
                compile = "erlc",
                run = "erl",
            },
            interpreted = false,
            custom_out = true,
        },
        python = {
            commands = {
                run = "python3",
            },
            interpreted = true,
        },
        scala = {
            use_build_system = true,
            build_system = "sbt",
        },
        rust = {
            use_build_system = true,
            build_system = "cargo",
        },
    },
    ext_match = {
        erl = "erlang",
        py = "python",
        c = "c",
        rs = "rust",
        lua = "lua",
        scala = "scala",
    },

    build_systems = {
        sbt = {
            compile = "sbt compile",
            run = "sbt run",
        },
        cargo = {
            compile = "cargo build",
            run = "cargo run",
        }
    }
}

function M.setup()
    for _, conf in pairs(M.languages) do
        if conf.use_build_system then
            conf.commands = M.build_systems[conf.build_system]
        elseif conf.out_dir then
            local opts_c = conf.out_opt_c or ""
            local opts_r = conf.out_opt_r or ""
            local r = string.format("%s %s %s ", conf.commands.run, opts_r, conf.out_dir)
            local c = string.format("%s %s %s ", conf.commands.compile, opts_c, conf.out_dir)
            conf.commands.compile = c
            conf.commands.run = r
        end
    end


end

return M
