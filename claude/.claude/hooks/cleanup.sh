#!/usr/bin/env bash

CLAUDE_DIR="$HOME/.claude"

# paste-cache: older than 7 days
find "$CLAUDE_DIR/paste-cache" -mindepth 1 -mtime +7 -delete 2>/dev/null

# file-history: older than 14 days
find "$CLAUDE_DIR/file-history" -mindepth 1 -mtime +14 -delete 2>/dev/null

# backups: keep only newest 1
ls -t "$CLAUDE_DIR/backups"/.claude.json.backup.* 2>/dev/null | tail -n +2 | xargs rm -f 2>/dev/null

# projects: nuke entirely (local CLAUDE.md used instead of memory)
rm -rf "$CLAUDE_DIR/projects" 2>/dev/null

# shell-snapshots: older than 7 days
find "$CLAUDE_DIR/shell-snapshots" -mindepth 1 -mtime +7 -delete 2>/dev/null

exit 0
