return {
    -- GitHub Copilot inline ghost-text suggestions
    {
        "zbirenbaum/copilot.lua",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                keymap = {
                    accept = "<M-l>",
                    accept_word = "<M-w>",
                    accept_line = "<M-e>",
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<M-x>",
                },
            },
            panel = { enabled = false },
        },
    },

    -- Completion engine
    {
        "saghen/blink.cmp",
        event = "InsertEnter",
        version = "*",
        opts = {
            keymap = {
                preset = "default",
                ["<CR>"] = { "select_and_accept", "fallback" },
            },
            appearance = { nerd_font_variant = "mono" },
            sources = {
                default = { "lsp", "path", "buffer", "lazydev" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            completion = {
                documentation = { auto_show = true },
                list = { selection = { preselect = true, auto_insert = false } },
            },
        },
    },

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
