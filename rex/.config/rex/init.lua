-- Tab and pane shortcuts. Copy/paste keep Rex's native Cmd+C / Cmd+V.
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts
rex.bind("cmd+shift+t", "client.tab.new")
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })
rex.bind("cmd+w", "pane.close")

-- Appearance and input are app preferences, written by scripts/bootstrap.sh.
