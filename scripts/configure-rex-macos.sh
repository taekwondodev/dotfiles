#!/bin/bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "This script requires macOS." >&2; exit 1; }
command -v rex >/dev/null || { echo "Open Rex and run this script from its terminal." >&2; exit 1; }

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${1:-}" ]]; then
    set -- --client "$1"
else
    set --
fi

# These are app preferences, not init.lua fields (Rex Beta 0.1.0, build 1541).
# Write only appearance/input preferences, never session or connection state.
# Import first so a missing/ambiguous app client fails before changing defaults.
rex "$@" "do" client.theme.import path="$DOTFILES_DIR/rex/.config/rex/themes/rose-pine-moon"

defaults write com.superlogical.rex Workspace.terminalFontName -string "JetBrainsMono Nerd Font Mono"
defaults write com.superlogical.rex Workspace.terminalFontPointSize -float 15
defaults write com.superlogical.rex Workspace.terminalCellHeightPercent -float 35
defaults write com.superlogical.rex Workspace.terminalAllowsLigatures -bool true
defaults write com.superlogical.rex Workspace.terminalCursorStyle -string block
defaults write com.superlogical.rex Workspace.terminalCursorStyleForced -bool false
defaults write com.superlogical.rex Workspace.terminalOptionKeyBehavior -string left
defaults write com.superlogical.rex Workspace.terminalCopyOnSelect -bool true

printf '%s\n' "Rex preferences saved. If not applied live, quit/reopen Rex when convenient."
