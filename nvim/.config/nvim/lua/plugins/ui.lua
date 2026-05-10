return {
    { "nvim-tree/nvim-web-devicons", lazy = true },
    { "mskelton/termicons.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },

    -- Ayu mirage: matches ghostty palette exactly, transparent bg lets ghostty bg bleed through
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
            { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
            { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
            { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
            { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
            { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker" },
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

    -- Markdown rendering in normal mode
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        opts = {},
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

    -- Keymap hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
        },
    },
}
