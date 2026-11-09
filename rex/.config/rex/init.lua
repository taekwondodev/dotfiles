-- Tab and pane shortcuts. Copy/paste keep Rex's native Cmd+C / Cmd+V.
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts
rex.bind("cmd+shift+t", "client.tab.new")
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })

-- Cmd+W asks before closing a pane whose foreground program is dev.
local function runs_dev(block_id)
  local p = rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
  local script = p and p.foreground and p.foreground.script
  return script ~= nil and script:match("/dev$") ~= nil
end

local function confirm_close()
  -- Rex has no dialogs; actions must finish within 30s, so the dialog gives up first.
  local r = rex.exec({ "osascript", "-e", [[display dialog "In questo pannello gira dev. Sei sicuro di volerlo chiudere?" ]]
    .. [[buttons {"Annulla", "Chiudi"} default button "Annulla" cancel button "Annulla" ]]
    .. [[with icon caution giving up after 25]] }, { timeout = 28 })
  return r ~= nil and r.ok and r.stdout:find("button returned:Chiudi", 1, true) ~= nil
end

rex.action{
  name = "close_pane_guarded",
  title = "Close Pane (Confirm for dev)",
  run = function(ctx)
    if runs_dev(ctx.block_id) and not confirm_close() then return end
    rex.client.queue("pane.close")
  end,
}
rex.bind("cmd+w", "close_pane_guarded")

-- Appearance and input are app preferences, written by scripts/bootstrap.sh.
