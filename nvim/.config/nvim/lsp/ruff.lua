-- Lint diagnostics and fixes. Pyright owns hover; conform owns formatting,
-- gated on a project ruff config (lua/plugins/coding.lua).
return {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "ruff.toml", ".ruff.toml", "pyproject.toml", ".git" },
    -- A project without a ruff config keeps its own import style (e.g.
    -- OpenStack's one import per line). Ruff merges editor settings even into
    -- a project config, so the fallback is sent only when there is none.
    before_init = function(params, config)
        if not require("config.ruff").has_project_config(config.root_dir) then
            params.initializationOptions = {
                settings = { configuration = { lint = { ignore = { "I001" } } } },
            }
        end
    end,
    on_attach = function(client)
        client.server_capabilities.hoverProvider = false
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
}
