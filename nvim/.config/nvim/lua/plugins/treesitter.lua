return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        lazy = false,
        config = function()
            require("nvim-treesitter").setup()

            require("nvim-treesitter").install({
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
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "*",
                callback = function()
                    pcall(vim.treesitter.start)
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },
}
