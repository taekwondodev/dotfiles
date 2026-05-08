return {
    -- Filesystem as editable buffer (replaces nvim-tree)
    {
        "stevearc/oil.nvim",
        lazy = false,
        keys = {
            { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
        },
        opts = {
            columns = { "icon" },
            view_options = { show_hidden = true },
            float = { padding = 2, border = "rounded" },
        },
    },

    -- Fast file marking / navigation
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
            { "<C-e>", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
            { "<C-h>", function() require("harpoon"):list():select(1) end },
            { "<C-t>", function() require("harpoon"):list():select(2) end },
            { "<C-n>", function() require("harpoon"):list():select(3) end },
            { "<C-s>", function() require("harpoon"):list():select(4) end },
        },
        config = function()
            require("harpoon"):setup()
        end,
    },

    -- Fuzzy finding (replaces telescope)
    {
        "ibhagwan/fzf-lua",
        keys = {
            { "<leader>pf", function() require("fzf-lua").files() end, desc = "Find files" },
            { "<C-p>", function() require("fzf-lua").git_files() end, desc = "Git files" },
            { "<leader>ps", function() require("fzf-lua").live_grep() end, desc = "Live grep" },
            { "<leader>pws", function() require("fzf-lua").grep_cword() end, desc = "Grep word" },
            { "<leader>pWs", function() require("fzf-lua").grep_cWORD() end, desc = "Grep WORD" },
            { "<leader>vh", function() require("fzf-lua").help_tags() end, desc = "Help tags" },
        },
        opts = {
            winopts = { border = "rounded", preview = { border = "rounded" } },
        },
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
            end,
        },
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
