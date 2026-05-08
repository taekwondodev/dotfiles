return {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            inlayHints = {
                bindingModeHints = { enable = true },
                closureReturnTypeHints = { enable = "always" },
            },
        },
    },
}
