return {
    -- Fast file marking / navigation
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
            { "<C-e>", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
            { "<M-1>", function() require("harpoon"):list():select(1) end },
            { "<M-2>", function() require("harpoon"):list():select(2) end },
            { "<M-3>", function() require("harpoon"):list():select(3) end },
            { "<M-4>", function() require("harpoon"):list():select(4) end },
        },
        config = function()
            require("harpoon"):setup()
        end,
    },

    -- Inline git signs + hunk navigation
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
            },
            on_attach = function(buf)
                local gs = package.loaded.gitsigns
                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = buf, desc = desc })
                end
                map("n", "]h", gs.next_hunk, "Next hunk")
                map("n", "[h", gs.prev_hunk, "Prev hunk")
                map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
                map("n", "<leader>gd", gs.diffthis, "Diff this")
                map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
                map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
                map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
            end,
        },
    },

    -- Advanced diff viewer
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
        opts = {},
    },

    -- Git workflow (ThePrimeagen staple)
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "Gdiff", "Gread", "Gwrite", "GBrowse" },
        keys = {
            { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
        },
    },

    -- Visual undo history
    {
        "mbbill/undotree",
        keys = {
            { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" },
        },
    },

    -- Jump anywhere with s + 2 chars
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        },
    },

    -- Highlight and navigate TODO/FIXME/HACK comments
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPre", "BufNewFile" },
        opts = {},
        keys = {
            { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
            { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
            { "<leader>st", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
        },
    },

    -- Session save/restore per directory
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
        keys = {
            { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
            { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
            { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save session" },
        },
    },

    -- Diagnostics panel
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        keys = {
            { "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble diagnostics" },
            { "<leader>tl", "<cmd>Trouble loclist toggle<cr>", desc = "Trouble loclist" },
            { "<leader>tq", "<cmd>Trouble qflist toggle<cr>", desc = "Trouble quickfix" },
        },
        opts = {},
    },
}
