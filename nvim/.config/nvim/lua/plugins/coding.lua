return {
    -- Better LSP rename with live preview
    {
        "smjonas/inc-rename.nvim",
        cmd = "IncRename",
        config = true,
    },

    -- Split/join code blocks
    {
        "Wansmer/treesj",
        keys = {
            { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
        },
        opts = { use_default_keymaps = false, max_join_length = 150 },
    },

    -- Align text by character
    {
        "echasnovski/mini.align",
        opts = {},
        keys = {
            { "ga", mode = { "n", "v" } },
            { "gA", mode = { "n", "v" } },
        },
    },

    -- Linting
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {}
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },

    -- Better Lua LSP for nvim config
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {},
    },


    -- Auto-close brackets/quotes
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },

    -- Surround motions (cs, ds, ys)
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        opts = {},
    },

    -- Treesitter-aware commenting (gc / gcc)
    {
        "folke/ts-comments.nvim",
        event = "VeryLazy",
        opts = {},
    },

    -- Formatting engine (replaces lsp format)
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                go = { "gofumpt", "goimports" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                fish = { "fish_indent" },
                python = { "black" },
                java = { "google_java_format" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
    },
}
