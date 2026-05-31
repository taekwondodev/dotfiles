local map = vim.keymap.set

-- Better j/k for wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Window splits
map("n", "<leader>-", "<C-W>s", { desc = "Split below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split right" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep screen centered when searching
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "=ap", "ma=ap'a")

-- Paste without clobbering register
map("x", "<leader>p", [["_dP]])

-- System clipboard
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])

-- Ctrl-C as Escape in insert mode
map("i", "<C-c>", "<Esc>")

-- Cmd+Z as undo (macOS style)
map({ "n", "v" }, "<D-z>", "u")
map("i", "<D-z>", "<C-o>u")

-- Toggle terminal
map({ "n", "t" }, "<D-j>", function() Snacks.terminal(nil, { cwd = vim.fn.getcwd() }) end, { desc = "Toggle terminal" })

-- Disable ex mode
map("n", "Q", "<nop>")

-- Format with conform
map("n", "<leader>f", function()
    require("conform").format({ async = true })
end, { desc = "Format file" })

-- Make current file executable
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Restart LSP
map("n", "<leader>zig", "<cmd>LspRestart<cr>")

-- Buffer management
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete other buffers" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Source current file
map("n", "<leader><leader>", function()
    vim.cmd("so")
end)

-- Quit nvim entirely when only sidebar windows remain
vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        local real_wins = vim.tbl_filter(function(w)
            if vim.api.nvim_win_get_config(w).relative ~= "" then return false end
            return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
        end, vim.api.nvim_list_wins())
        if #real_wins <= 1 then
            vim.cmd("qa!")
        end
    end,
})
