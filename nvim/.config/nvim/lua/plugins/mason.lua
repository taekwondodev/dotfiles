return {
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()

            local ensure_installed = {
                -- LSP servers
                "gopls",
                "dockerfile-language-server",
                "rust-analyzer",
                "clangd",
                "typescript-language-server",
                "bash-language-server",
                "lua-language-server",
                "pyright",
                "jdtls",
                -- Formatters
                "stylua",
                "shfmt",
                "prettier",
                "gofumpt",
                "black",
                "google-java-format",
            }

            local mr = require("mason-registry")
            mr.refresh(function()
                for _, tool in ipairs(ensure_installed) do
                    local ok, p = pcall(mr.get_package, tool)
                    if ok and not p:is_installed() then
                        p:install()
                    end
                end
            end)
        end,
    },
}
