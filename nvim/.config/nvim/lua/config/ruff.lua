local M = {}

-- Mirrors ruff's own discovery: a ruff.toml, or a pyproject.toml with a
-- [tool.ruff] section, in dir or any ancestor.
function M.has_project_config(dir)
    local found = vim.fs.find(function(name, path)
        if name == "ruff.toml" or name == ".ruff.toml" then
            return true
        end
        if name ~= "pyproject.toml" then
            return false
        end
        for line in io.lines(vim.fs.joinpath(path, name)) do
            if line:match("^%[tool%.ruff[%].]") then
                return true
            end
        end
        return false
    end, { path = dir, upward = true, limit = 1 })
    return #found > 0
end

return M
