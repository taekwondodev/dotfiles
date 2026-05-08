return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua", "vim", "vimdoc",
                    "go", "gomod", "gosum",
                    "c", "cpp",
                    "typescript", "javascript", "tsx", "json",
                    "bash", "fish",
                    "html", "css",
                    "markdown", "markdown_inline",
                    "yaml", "toml",
                    "python",
                    "java",
                    "gitcommit", "git_config",
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
}
