return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_dir = function(bufnr, on_dir)
        local markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", ".venv", "venv", "venv311" }
        local root = vim.fs.root(bufnr, markers)
        on_dir(root or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h"))
    end,
    before_init = function(_, config)
        for _, dir in ipairs({ ".venv", "venv", "venv311" }) do
            local python = config.root_dir .. "/" .. dir .. "/bin/python"
            if vim.fn.executable(python) == 1 then
                config.settings.python.pythonPath = python
                break
            end
        end
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
