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
            { "<leader>e",        function() Snacks.explorer() end, desc = "Explorer" },
            { "<D-b>",            function() Snacks.explorer() end, desc = "Explorer", mode = { "n", "i", "v" } },
            -- Find
            { "<leader>ff",       function() require("config.rex").picker("files") end, desc = "Files" },
            { "<leader>fg",       function() require("config.rex").picker("grep") end,  desc = "Grep" },
            { "<leader>fw",       function() require("config.rex").picker("grep_word", { search = vim.fn.expand("<cword>") }) end, desc = "Word under cursor" },
            { "<leader>fl",       function() Snacks.picker.lines() end,       desc = "Lines in buffer" },
            { "<leader>fs",       function() Snacks.picker.lsp_symbols() end, desc = "Symbols" },
            { "<leader>fh",       function() Snacks.picker.help() end,        desc = "Help" },
            -- Git
            { "<leader>gg",       function() require("config.rex").lazygit() end,      desc = "LazyGit" },
            { "<leader>gl",       function() require("config.rex").lazygit("log") end, desc = "Log" },
        },
    },
}
