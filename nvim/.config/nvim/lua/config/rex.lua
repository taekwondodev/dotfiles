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

local function guarded(title, fn)
    local ok, err = pcall(fn)
    if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR, { title = title })
    end
end

-- Runs `spec.command` in a centered Rex float over the focused pane. When the
-- program exits, the float closes, the pane regains focus and `spec.on_exit` runs.
-- Opening the same `spec.key` again focuses the existing float.
local function float(spec)
    local session = vim.env.REX_SESSION
    if blocks[spec.key] then
        rex({ "focus", "-s", session, blocks[spec.key] })
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
    local created = vim.json.decode(rex({ "api", "call", "session.new_layer", vim.json.encode({
        session_id = session,
        window_id = window.window_id,
        bounds = { 0.05, 0.05, 0.9, 0.9 },
        focus = true,
        layout = { block = {
            flavor = "com.superlogical.terminal.shell",
            label = spec.label,
            options = { shell = "none", cwd = spec.cwd, command = spec.command },
        } },
    }) }))
    local block = assert(created.block_ids[1], "Rex did not return the " .. spec.label .. " block")
    blocks[spec.key] = block
    vim.system({ vim.fn.exepath("rex"), "wait", "-s", session, "--json", block }, { text = true }, vim.schedule_wrap(function(result)
        local decoded, event = pcall(vim.json.decode, result.stdout or "")
        if not decoded or type(event) ~= "table" or (event.exit_code == nil and event.block_id ~= block) then
            vim.notify("Could not observe " .. spec.label .. " exit; leaving its pane open: " .. (result.stderr or ""), vim.log.levels.WARN)
            return
        end
        -- A terminal can exit without its block disappearing (e.g. an unseen tab).
        -- The program may already have closed it; closing again is harmless.
        vim.system({ vim.fn.exepath("rex"), "block", "close", "-s", session, block }, { timeout = 10000 }):wait()
        blocks[spec.key] = nil
        vim.system({ vim.fn.exepath("rex"), "focus", "-s", session, source })
        if spec.on_exit then
            spec.on_exit()
        end
    end))
end

function M.lazygit(mode)
    guarded("Rex LazyGit", function()
        assert(vim.env.REX_SESSION, "Native LazyGit requires a Rex session")
        for _, tool in ipairs({ "rex", "lazygit", "python3" }) do
            assert(vim.fn.executable(tool) == 1, tool .. " is not available")
        end

        local cwd = vim.fs.root(0, ".git") or vim.fn.getcwd()
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
        float({
            key = "lazygit\n" .. cwd .. "\n" .. (mode or ""),
            label = "LazyGit",
            cwd = cwd,
            command = command,
            on_exit = function()
                vim.cmd("checktime")
                if package.loaded.gitsigns then
                    require("gitsigns").refresh()
                end
            end,
        })
    end)
end

-- Opens a Snacks picker in a second Neovim inside a Rex float. Outside Rex the
-- picker stays inline. The chosen items open in this editor's main window.
function M.picker(source, opts)
    if not vim.env.REX_SESSION then
        Snacks.picker.pick(source, opts)
        return
    end
    guarded("Rex picker", function()
        assert(vim.fn.executable("rex") == 1, "rex is not available")
        local request = {
            source = source,
            opts = opts or {},
            server = vim.v.servername,
            win = require("snacks.picker.core.main").new():get(),
        }
        float({
            key = "picker",
            label = "Search",
            cwd = vim.fn.getcwd(),
            -- Rex starts the float with its server's environment; keep this PATH for fd and rg.
            command = { "/usr/bin/env", "PATH=" .. vim.env.PATH, "REX_PICKER=" .. vim.json.encode(request), vim.v.progpath },
        })
    end)
end

-- Picker child: show the requested picker fullscreen, hand the selection to the
-- launching editor and exit, which closes the float.
function M.serve_picker()
    local request = vim.json.decode(vim.env.REX_PICKER)
    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
            local opts = vim.tbl_extend("force", request.opts, {
                layout = { fullscreen = true },
                on_close = vim.schedule_wrap(function() vim.cmd("qa!") end),
                confirm = function(picker, _, action)
                    local items = vim.tbl_map(function(item)
                        return { file = Snacks.picker.util.path(item), pos = item.pos }
                    end, picker:selected({ fallback = true }))
                    local ok, err = pcall(function()
                        local parent = vim.fn.sockconnect("pipe", request.server, { rpc = true })
                        vim.rpcrequest(parent, "nvim_exec_lua", "return require('config.rex').open_items(...)",
                            { request.win, items, action.cmd })
                    end)
                    if ok then
                        picker:close()
                    else
                        Snacks.notify.error(tostring(err), { title = "Rex picker" })
                    end
                end,
            })
            Snacks.picker.pick(request.source, opts)
        end,
    })
end

-- Called by the picker child over RPC; mirrors Snacks' jump action.
function M.open_items(win, items, cmd)
    if #items == 0 then
        return
    end
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    end
    local current = vim.api.nvim_get_current_buf()
    local empty = vim.bo[current].buftype == "" and vim.bo[current].filetype == ""
        and vim.api.nvim_buf_get_name(current) == ""
        and vim.deep_equal(vim.api.nvim_buf_get_lines(current, 0, -1, false), { "" })
    if not empty then
        vim.cmd("normal! m'")
    end

    local first
    for _, item in ipairs(items) do
        local buf = vim.fn.bufadd(item.file)
        vim.bo[buf].buflisted = true
        first = first or buf
    end
    local open = ({ split = "sbuffer", vsplit = "vert sbuffer", tab = "tab sbuffer" })[cmd] or "buffer"
    vim.cmd(open .. " " .. first)

    local pos = items[1].pos
    if pos and pos[1] > 0 then
        vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] })
        vim.cmd("normal! zzzv")
    end
    if empty and first ~= current and #vim.fn.win_findbuf(current) == 0 then
        vim.api.nvim_buf_delete(current, { force = true })
    end
end

return M
