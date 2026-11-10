return {
    { "nvim-tree/nvim-web-devicons", lazy = true },
    { "mskelton/termicons.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },

    -- Ayu mirage: transparent bg lets the terminal bg bleed through
    {
        "Shatur/neovim-ayu",
        lazy = false,
        priority = 1000,
        config = function()
            require("ayu").setup({
                mirage = true,
                overrides = {
                    Normal = { bg = "None" },
                    NormalFloat = { bg = "None" },
                    NormalNC = { bg = "None" },
                },
            })
            vim.cmd.colorscheme("ayu-mirage")
            vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#5ccfe6" })
            vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { link = "Normal" })
        end,
    },

    -- Buffer tab bar
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                separator_style = "slope",
            },
        },
    },

    -- Fancy cmdline, messages and popups
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            routes = {
                {
                    filter = {
                        event = "msg_show",
                        any = {
                            { find = "%d+L, %d+B" },
                            { find = "; after #%d+" },
                            { find = "; before #%d+" },
                        },
                    },
                    view = "mini",
                },
                {
                    filter = { event = "notify", find = "No information available" },
                    opts = { skip = true },
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
            },
        },
        keys = {
            { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
            { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = { "i", "n", "s" } },
            { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = { "i", "n", "s" } },
        },
        config = function(_, opts)
            if vim.o.filetype == "lazy" then
                vim.cmd([[messages clear]])
            end
            require("noice").setup(opts)
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "ayu_mirage",
                component_separators = "|",
                section_separators = "",
                globalstatus = true,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- Native Markdown rendering in the Neovim buffer
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        opts = {},
    },

    -- Browser-based HTML/Markdown preview with live updates
    {
        "brianhuster/live-preview.nvim",
        ft = { "markdown", "html", "svg" },
        cmd = "LivePreview",
        opts = {
            browser = "default",
            dynamic_root = true,
            sync_scroll = true,
            picker = "snacks",
            address = "127.0.0.1",
        },
        config = function(_, opts)
            require("livepreview.config").set(opts)
        end,
        init = function()
            -- Buffer-local so `Space p` only shows up where a preview exists.
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "html", "svg" },
                callback = function(event)
                    vim.keymap.set("n", "<leader>p", "<cmd>LivePreview start<cr>",
                        { buffer = event.buf, desc = "Preview in browser" })
                end,
            })
        end,
    },


    -- Scrollbar indicator
    {
        "dstein64/nvim-scrollview",
        event = "VeryLazy",
        opts = {
            current_only = true,
            winblend = 75,
        },
    },

    -- Styled inline diagnostics with background
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "LspAttach",
        priority = 1000,
        opts = {
            preset = "modern",
            signs = {
                arrow = "",
                up_arrow = "",
            },
            options = {
                enable_on_insert = true,
            },
        },
    },

    -- Keymap hints. Group names are the mnemonic: Space + group + action.
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
            spec = {
                { "<leader>b", group = "Buffer" },
                { "<leader>c", group = "Code" },
                { "<leader>d", group = "Diagnostics" },
                { "<leader>f", group = "Find" },
                { "<leader>g", group = "Git" },
                { "<leader>h", group = "Harpoon" },
                { "<leader>q", group = "Session" },
                { "[", group = "Prev" },
                { "]", group = "Next" },
            },
        },
    },
}
