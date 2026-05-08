return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_dir = function(bufnr, on_dir)
        local markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", ".venv", "venv", "venv311" }
        local root = vim.fs.root(bufnr, markers)
        on_dir(root or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h"))
    end,
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
            },
        },
    },
}
