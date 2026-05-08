require("config.options")
require("config.keymaps")
require("config.lazy")

vim.lsp.enable({ "gopls", "clangd", "ts_ls", "bashls", "lua_ls", "pyright", "jdtls", "rust_analyzer", "dockerls" })
