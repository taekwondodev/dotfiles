vim.filetype.add({
    filename = {
        ["compose.yaml"] = "yaml.docker-compose",
        ["compose.yml"] = "yaml.docker-compose",
        ["compose.test.yaml"] = "yaml.docker-compose",
        ["docker-compose.yaml"] = "yaml.docker-compose",
        ["docker-compose.yml"] = "yaml.docker-compose",
    },
})

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

vim.opt.guicursor = ""
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.confirm = true
vim.opt.clipboard = "unnamedplus"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.fillchars = {
    foldopen = "▾",
    foldclose = "▸",
    fold = " ",
    foldsep = " ",
    diff = "╱",
    eob = " ",
}

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 150 })
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(event)
        local buf = event.buf
        if vim.tbl_contains({ "gitcommit" }, vim.bo[buf].filetype) then return end
        if vim.b[buf].last_loc then return end
        vim.b[buf].last_loc = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "lspinfo", "man", "notify", "qf", "startuptime", "checkhealth" },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(event)
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        if event.match:match("^%w%w+:[\\/][\\/]") then return end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})


-- Auto-resize splits on terminal resize
vim.api.nvim_create_autocmd("VimResized", {
    pattern = "*",
    command = "wincmd =",
})


-- LSP attach: keymaps + inlay hints
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local buf = args.buf
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end

        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "gr", vim.lsp.buf.references, "References")
        map("n", "K", vim.lsp.buf.hover, "Hover docs")
        vim.keymap.set("n", "<leader>rn", ":IncRename ", { buffer = buf, desc = "Rename symbol" })
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic float")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")

        if vim.lsp.inlay_hint and client and client:supports_method("textDocument/inlayHint") then
            if vim.fn.filereadable(vim.api.nvim_buf_get_name(buf)) == 1 then
                vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            end
        end
    end,
})

-- :q on the last file window of a tab also closes sidebars (explorer, floats),
-- so the same :q exits Neovim. Windows close without force, and :q itself still
-- refuses unsaved changes or running terminal jobs.
vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        local current = vim.api.nvim_get_current_win()
        local others = vim.tbl_filter(function(w)
            return w ~= current
        end, vim.api.nvim_tabpage_list_wins(0))
        for _, w in ipairs(others) do
            local is_float = vim.api.nvim_win_get_config(w).relative ~= ""
            if not is_float and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then
                return
            end
        end
        for _, w in ipairs(others) do
            pcall(vim.api.nvim_win_close, w, false)
        end
    end,
})

vim.diagnostic.config({
    virtual_text = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚",
            [vim.diagnostic.severity.WARN] = "󰀪",
            [vim.diagnostic.severity.INFO] = "󰋽",
            [vim.diagnostic.severity.HINT] = "󰌶",
        },
    },
    underline = true,
    update_in_insert = true,
    severity_sort = true,
    float = { border = "rounded", source = true },
})
