return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = { enabled = true },
            scroll = { enabled = true },
            bufdelete = { enabled = true },
            -- Directories open the explorer from the autocmd below instead.
            explorer = { replace_netrw = false },
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

            -- Snacks' replace_netrw shows the explorer before the UI attaches when
            -- Neovim starts on a directory, which kills neopane 0.2.2's daemon
            -- ("BadMessage"). Opening it after VimEnter works in both nvim and neopane.
            vim.api.nvim_create_autocmd("BufEnter", {
                group = vim.api.nvim_create_augroup("directory_explorer", { clear = true }),
                callback = function(event)
                    if event.file == "" or vim.fn.isdirectory(event.file) == 0 then
                        return
                    end
                    local function open()
                        Snacks.explorer.open({ cwd = event.file })
                        Snacks.bufdelete.delete(event.buf)
                    end
                    if vim.v.vim_did_enter == 1 then
                        open()
                    else
                        vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = vim.schedule_wrap(open) })
                    end
                end,
            })
        end,
        keys = {
            { "<leader>e",        function() Snacks.explorer() end, desc = "Explorer" },
            { "<D-b>",            function() Snacks.explorer() end, desc = "Explorer", mode = { "n", "i", "v" } },
            -- Find
            { "<leader>ff",       function() Snacks.picker.files() end,       desc = "Files" },
            { "<leader>fg",       function() Snacks.picker.grep() end,        desc = "Grep" },
            { "<leader>fw",       function() Snacks.picker.grep_word() end,   desc = "Word under cursor" },
            { "<leader>fl",       function() Snacks.picker.lines() end,       desc = "Lines in buffer" },
            { "<leader>fs",       function() Snacks.picker.lsp_symbols() end, desc = "Symbols" },
            { "<leader>fh",       function() Snacks.picker.help() end,        desc = "Help" },
            -- Git
            { "<leader>gg",       function() require("config.rex").lazygit() end,      desc = "LazyGit" },
            { "<leader>gl",       function() require("config.rex").lazygit("log") end, desc = "Log" },
        },
    },
}
