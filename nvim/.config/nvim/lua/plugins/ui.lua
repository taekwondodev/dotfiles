return {
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

    -- Keymap hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
        },
    },
}
