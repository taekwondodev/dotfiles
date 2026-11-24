local function has_ruff_config(_, ctx)
    return require("config.ruff").has_project_config(ctx.dirname)
end

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

    -- Schema catalog for yamlls and jsonls
    { "b0o/schemastore.nvim", lazy = false },

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
                python = { "ruff_fix", "ruff_format" },
                java = { "google_java_format" },
                swift = { "swift" },
                terraform = { "terraform_fmt" },
                terraform_vars = { "terraform_fmt" },
            },
            -- Only projects that adopt ruff get rewritten on save; others
            -- (e.g. OpenStack style) keep their own formatting.
            formatters = {
                ruff_fix = { condition = has_ruff_config },
                ruff_format = { condition = has_ruff_config },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
                quiet = true,
            },
        },
    },
}
