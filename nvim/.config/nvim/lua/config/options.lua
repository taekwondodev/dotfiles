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

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        if event.match:match("^%w%w+:[\\/][\\/]") then return end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

-- Native 0.12 completion
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- Auto-resize splits on terminal resize
vim.api.nvim_create_autocmd("VimResized", {
    pattern = "*",
    command = "wincmd =",
})


-- LSP attach: keymaps + native completion + inlay hints
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
        map("i", "<C-Space>", vim.lsp.completion.get, "Trigger completion")

        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
        end

        if vim.lsp.inlay_hint and client and client:supports_method("textDocument/inlayHint") then
            if vim.fn.filereadable(vim.api.nvim_buf_get_name(buf)) == 1 then
                vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            end
        end
    end,
})

vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        local ui_wins = {}
        local real_count = 0
        local has_explorer = false
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(w)
            local ft = vim.bo[buf].filetype
            if vim.bo[buf].buftype == "" then
                real_count = real_count + 1
            else
                table.insert(ui_wins, w)
                if ft:match("snacks_picker") or ft == "snacks_layout_box" then
                    has_explorer = true
                end
            end
        end
        if real_count == 0 and has_explorer then
            -- quitting from explorer with no files open → quit all
            vim.cmd("qa")
        elseif real_count == 1 and not has_explorer then
            -- last real window, no explorer → close noice/scrollview noise then quit
            for _, w in ipairs(ui_wins) do
                pcall(vim.api.nvim_win_close, w, true)
            end
        end
        -- real_count >= 1 and has_explorer → do nothing, :q closes the file and focuses explorer
    end,
})

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = true },
})
