"""Return from a Rex-owned LazyGit process to its launching Neovim window."""
import json
import os
from pathlib import Path
import subprocess
import sys

try:
    filename = str(Path(sys.argv[1]).absolute())
    line = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    if line < 0:
        raise ValueError("Line must not be negative")
    window = int(os.environ["NEOREX_EDITOR_WIN"])
    lua = """(function(a)
        assert(vim.api.nvim_win_is_valid(a[2]), "Source editor window was closed")
        vim.api.nvim_set_current_win(a[2])
        vim.api.nvim_cmd({cmd="edit", args={a[1]}, magic={file=false}}, {})
        if a[3] > 0 then
            vim.api.nvim_win_set_cursor(0, {math.min(a[3], vim.api.nvim_buf_line_count(0)), 0})
        end
        return true
    end)(_A)"""
    expr = "luaeval(" + json.dumps(lua) + ", " + json.dumps([filename, window, line], ensure_ascii=False) + ")"
    subprocess.run(
        [os.environ["NEOREX_NVIM"], "--server", os.environ["NVIM"], "--remote-expr", expr],
        check=True, capture_output=True, text=True, timeout=15,
    )
    # Only close the native terminal after the remote edit succeeded.
    subprocess.run(
        [os.environ["NEOREX_REX"], "block", "close", "-s", os.environ["REX_SESSION"], os.environ["REX_BLOCK"]],
        check=True, capture_output=True, text=True, timeout=10,
    )
except (ValueError, KeyError, IndexError, OSError, subprocess.SubprocessError) as error:
    detail = getattr(error, "stderr", None) or str(error)
    sys.exit("Could not return to Neovim: " + detail)
