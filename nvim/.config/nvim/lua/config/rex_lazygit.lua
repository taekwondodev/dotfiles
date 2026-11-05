local M = {}
local blocks = {}

local function rex(args)
    local command = vim.list_extend({ vim.fn.exepath("rex") }, args)
    local result = vim.system(command, { text = true, timeout = 10000 }):wait()
    if result.code ~= 0 then
        error(vim.trim(result.stderr or result.stdout or "Rex command failed"))
    end
    return result.stdout
end

function M.open(mode)
    local ok, err = pcall(function()
        assert(vim.env.REX_SESSION, "Native LazyGit requires a Rex session")
        for _, tool in ipairs({ "rex", "lazygit", "python3" }) do
            assert(vim.fn.executable(tool) == 1, tool .. " is not available")
        end

        local session = vim.env.REX_SESSION
        local cwd = vim.fs.root(0, ".git") or vim.fn.getcwd()
        local key = cwd .. "\n" .. (mode or "")
        if blocks[key] then
            rex({ "focus", "-s", session, blocks[key] })
            return
        end

        -- The launcher's REX_BLOCK is stale after Neovim splits: query live focus.
        local state = vim.json.decode(rex({ "session", "inspect", session, "--json" }))
        local window
        for _, candidate in ipairs(state.windows) do
            if candidate.window_id == state.active_window_id then
                window = candidate
                break
            end
        end
        assert(window and window.focused_block_id, "No focused Rex editor pane")
        local source = window.focused_block_id
        local config = vim.fn.stdpath("config")
        local command = {
            "/usr/bin/env",
            "NVIM=" .. vim.v.servername,
            "NEOREX_NVIM=" .. vim.v.progpath,
            "NEOREX_REX=" .. vim.fn.exepath("rex"),
            "NEOREX_PYTHON=" .. vim.fn.exepath("python3"),
            "NEOREX_EDITOR_HELPER=" .. config .. "/bin/lazygit-editor.py",
            "NEOREX_EDITOR_WIN=" .. vim.api.nvim_get_current_win(),
            vim.fn.exepath("lazygit"),
            "--use-config-dir=" .. vim.fn.stdpath("state") .. "/lazygit",
            "--use-config-file=" .. config .. "/lazygit-rex.yml",
        }
        if mode then
            command[#command + 1] = mode
        end
        local created = vim.json.decode(rex({ "api", "call", "session.new_layer", vim.json.encode({
            session_id = session,
            window_id = window.window_id,
            bounds = { 0.05, 0.05, 0.9, 0.9 },
            focus = true,
            layout = { block = {
                flavor = "com.superlogical.terminal.shell",
                label = "LazyGit",
                options = { shell = "none", cwd = cwd, command = command },
            } },
        }) }))
        local block = assert(created.block_ids[1], "Rex did not return the LazyGit block")
        blocks[key] = block
        vim.system({ vim.fn.exepath("rex"), "wait", "-s", session, "--json", block }, { text = true }, vim.schedule_wrap(function(result)
            local decoded, event = pcall(vim.json.decode, result.stdout or "")
            if not decoded or type(event) ~= "table" or (event.exit_code == nil and event.block_id ~= block) then
                vim.notify("Could not observe LazyGit exit; leaving its pane open: " .. (result.stderr or ""), vim.log.levels.WARN)
                return
            end
            -- A terminal can exit without its block disappearing (e.g. an unseen tab).
            -- The editor callback may already have closed it; closing again is harmless.
            vim.system({ vim.fn.exepath("rex"), "block", "close", "-s", session, block }, { timeout = 10000 }):wait()
            blocks[key] = nil
            vim.system({ vim.fn.exepath("rex"), "focus", "-s", session, source })
            vim.cmd("checktime")
            if package.loaded.gitsigns then
                require("gitsigns").refresh()
            end
        end))
    end)
    if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Rex LazyGit" })
    end
end

return M
