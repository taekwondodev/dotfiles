local map = vim.keymap.set

-- Leader scheme: Space + group letter + action letter. Groups are named in
-- which-key (plugins/ui.lua) so holding Space shows the menu. Single-key
-- leader maps are reserved for the most frequent actions.

-- Better j/k for wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep screen centered when searching
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "=ap", "ma=ap'a")

-- Ctrl-C as Escape in insert mode
map("i", "<C-c>", "<Esc>")

-- Cmd+Z as undo (macOS style)
map({ "n", "v" }, "<D-z>", "u")
map("i", "<D-z>", "<C-o>u")

-- Disable ex mode
map("n", "Q", "<nop>")

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete other buffers" })

-- Code
map("n", "<leader>cf", function()
    require("conform").format({ async = true })
end, { desc = "Format file" })

-- Diagnostics (not LSP-only: linters and treesitter report here too)
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
