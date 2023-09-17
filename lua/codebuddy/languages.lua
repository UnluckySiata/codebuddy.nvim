local M = {
    languages = {
        cpp = {
            build = "clang++ -o {file} -std=c++20 {file}.{ext}",
            run = "./{file}"
        },
    },

    ext_match = {
        c = "c",
        cpp = "cpp",
        cxx = "cpp",
        erl = "erlang",
        ex = "elixir",
        exs = "elixir",
        java = "java",
        lua = "lua",
        py = "python",
        rs = "rust",
        scala = "scala",
    }
}

return M
