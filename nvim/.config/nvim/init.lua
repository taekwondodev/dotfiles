require("config.options")
require("config.keymaps")
require("config.lazy")

local all_servers = { "gopls", "clangd", "ts_ls", "bashls", "lua_ls", "pyright", "jdtls", "rust_analyzer", "dockerls", "terraformls", "docker_compose_language_service", "yamlls" }
local binaries = { gopls = "gopls", clangd = "clangd", ts_ls = "typescript-language-server", bashls = "bash-language-server", lua_ls = "lua-language-server", pyright = "pyright", jdtls = "jdtls", rust_analyzer = "rust-analyzer", dockerls = "docker-langserver", terraformls = "terraform-ls", docker_compose_language_service = "docker-compose-langserver", yamlls = "yaml-language-server" }

vim.lsp.enable(vim.tbl_filter(function(s)
    return vim.fn.executable(binaries[s] or s) == 1
end, all_servers))
