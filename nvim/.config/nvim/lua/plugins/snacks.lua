return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = { enabled = vim.env.REX_PICKER == nil }, -- not in Rex picker floats
            scroll = { enabled = true },
            bufdelete = { enabled = true },
            explorer = {
                replace_netrw = true,
            },
            picker = {
                sources = {
                    files = { hidden = true },
                    grep = { hidden = true },
                    grep_word = { hidden = true },
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
        config = function(_, opts)
            local snacks = require("snacks")
            snacks.setup(opts)

            -- Resolve file icons by basename instead of full path so extension-less
            -- special filenames (Makefile, Dockerfile, ...) get their devicon instead
            -- of the generic "󰈔 " fallback. nvim-web-devicons keys on extension, so it
            -- misses when handed a full path with no extension.
            local orig_icon = Snacks.util.icon
            Snacks.util.icon = function(name, cat, icon_opts)
                if cat == "file" then
                    name = vim.fs.basename(name)
                end
                return orig_icon(name, cat, icon_opts)
            end
        end,
        keys = {
            { "<leader>gg",  function() require("config.rex").lazygit() end,      desc = "LazyGit (Rex)" },
            { "<leader>gs",  function() require("config.rex").lazygit() end,      desc = "LazyGit status (Rex)" },
            { "<leader>gl",  function() require("config.rex").lazygit("log") end, desc = "LazyGit log (Rex)" },
            { "<leader>e",   function() Snacks.explorer() end,              desc = "Explorer" },
            { "<D-b>",       function() Snacks.explorer() end,              desc = "Explorer", mode = { "n", "i", "v" } },
            { "<leader>pf",  function() require("config.rex").picker("files") end,     desc = "Find files" },
            { "<C-p>",       function() require("config.rex").picker("git_files") end, desc = "Git files" },
            { "<leader>ps",  function() require("config.rex").picker("grep") end,      desc = "Live grep" },
            { "<leader>pws", function() require("config.rex").picker("grep_word", { search = vim.fn.expand("<cword>") }) end, desc = "Grep word" },
            { "<leader>vh",  function() Snacks.picker.help() end,           desc = "Help tags" },
            { "<leader>sb",  function() Snacks.picker.lines() end,          desc = "Buffer lines" },
            { "<leader>ss",  function() Snacks.picker.lsp_symbols() end,    desc = "LSP symbols" },
        },
    },
}
