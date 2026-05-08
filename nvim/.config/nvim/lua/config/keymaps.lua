local map = vim.keymap.set

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor position when joining lines
map("n", "J", "mzJ`z")

-- Keep screen centered when scrolling / searching
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "=ap", "ma=ap'a")

-- Paste without clobbering register
map("x", "<leader>p", [["_dP]])

-- System clipboard
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])
map({ "n", "v" }, "<leader>d", '"_d')

-- Ctrl-C as Escape in insert mode
map("i", "<C-c>", "<Esc>")

-- Disable ex mode
map("n", "Q", "<nop>")

-- Format with conform
map("n", "<leader>f", function()
    require("conform").format({ async = true })
end, { desc = "Format file" })

-- Quickfix / location list navigation
map("n", "<C-k>", "<cmd>cnext<CR>zz")
map("n", "<C-j>", "<cmd>cprev<CR>zz")
map("n", "<leader>k", "<cmd>lnext<CR>zz")
map("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Rename word under cursor (project-wide)
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make current file executable
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Restart LSP
map("n", "<leader>zig", "<cmd>LspRestart<cr>")

-- Go error handling snippets (ThePrimeagen style)
map("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>")
map("n", "<leader>ea", 'oassert.NoError(err, "")<Esc>F";a')
map("n", "<leader>ef", 'oif err != nil {<CR>}<Esc>Olog.Fatalf("error: %s\\n", err.Error())<Esc>jj')
map("n", "<leader>el", 'oif err != nil {<CR>}<Esc>O.logger.Error("error", "error", err)<Esc>F.;i')

-- Source current file
map("n", "<leader><leader>", function()
    vim.cmd("so")
end)
