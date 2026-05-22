return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = { enabled = true },
            scroll = { enabled = true },
            bufdelete = { enabled = true },
            explorer = {
                replace_netrw = true,
            },
            terminal = {
                win = {
                    position = "bottom",
                    height = 0.3,
                },
            },
            picker = {
                sources = {
                    files = { hidden = true },
                    grep = { hidden = true },
                    explorer = {
                        hidden = true,
                        ignored = true,
                        layout = {
                            preset = "sidebar",
                            preview = { main = true, enabled = false },
                        },
                    },
                },
            },
        },
        keys = {
            { "<leader>e",   function() Snacks.explorer() end,              desc = "Explorer" },
            { "<D-b>",       function() Snacks.explorer() end,              desc = "Explorer", mode = { "n", "i", "v" } },
            { "<leader>pf",  function() Snacks.picker.files() end,          desc = "Find files" },
            { "<C-p>",       function() Snacks.picker.git_files() end,      desc = "Git files" },
            { "<leader>ps",  function() Snacks.picker.grep() end,           desc = "Live grep" },
            { "<leader>pws", function() Snacks.picker.grep_word() end,      desc = "Grep word" },
            { "<leader>vh",  function() Snacks.picker.help() end,           desc = "Help tags" },
            { "<leader>sb",  function() Snacks.picker.lines() end,          desc = "Buffer lines" },
            { "<leader>ss",  function() Snacks.picker.lsp_symbols() end,    desc = "LSP symbols" },
        },
    },
}
