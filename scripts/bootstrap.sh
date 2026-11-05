#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
die()     { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

PROFILE=${1:-}
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TERMICONS_URL="https://github.com/mskelton/termicons"
REX_URL="https://www.superlogical.com/rex/docs/installation"
REX_CLI="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
REX_PREFS="com.superlogical.rex"
# Revisione di neorex verificata con Neovim 0.12 e Rex.
NEOREX_REVISION="066c0da5b3b4cc518c33f3fb0d17d2996752cbd9"

usage() {
    echo "Usage: $0 macos"
    echo ""
    echo "  macos   — nvim fish rex fastfetch hermes starship vim (brew)"
    exit 1
}

install_rust() {
    if ! command -v cargo &>/dev/null; then
        info "Cargo non trovato. Installazione Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
}

install_tree_sitter_cli() {
    if command -v tree-sitter &>/dev/null; then
        success "tree-sitter-cli già installato"
        return
    fi
    install_rust
    info "Installazione tree-sitter-cli..."
    cargo install tree-sitter-cli
}

install_manual() {
    local name=$1 url=$2 prompt=${3:-"Premi Enter quando hai installato $1..."}
    info "$name richiede installazione manuale."
    info "Apertura: $url"
    if command -v xdg-open &>/dev/null; then
        xdg-open "$url" 2>/dev/null || true
    elif command -v open &>/dev/null; then
        open "$url"
    else
        echo -e "${YELLOW}Apri manualmente:${NC} $url"
    fi
    read -rp "$(echo -e "${YELLOW}[WAIT]${NC} $prompt")"
}

install_rex() {
    if [[ -x "$REX_CLI" ]]; then
        success "Rex già installato"
        return
    fi
    install_manual Rex "$REX_URL" "Premi Enter quando Rex è installato e aperto (lascialo aperto fino alla fine del bootstrap)..."
    [[ -x "$REX_CLI" ]] || die "CLI di Rex non trovata: avvia Rex e rilancia il bootstrap."
}

install_neorex() {
    if [[ -x "$HOME/.local/bin/neorex" ]]; then
        success "neorex già installato"
        return
    fi
    info "Compilazione neorex ($NEOREX_REVISION)..."
    local build
    build=$(mktemp -d)
    git clone --filter=blob:none https://github.com/ian-pascoe/neorex.git "$build"
    git -C "$build" checkout --detach "$NEOREX_REVISION"
    cargo build --release --locked --manifest-path "$build/Cargo.toml"
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$build/target/release/neorex" "$HOME/.local/bin/neorex"
    rm -rf "$build"
    success "neorex installato"
}

install_hermes() {
    if command -v hermes &>/dev/null; then
        success "Hermes Agent già installato"
        return
    fi
    info "Installazione Hermes Agent..."
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    success "Hermes Agent installato"
}

install_macos() {
    [[ "$(uname -s)" == Darwin ]] || die "Il profilo macos richiede macOS."
    command -v brew &>/dev/null || die "Homebrew non trovato: https://brew.sh"
    info "Installazione dipendenze macOS..."
    brew install stow git starship neovim fd fastfetch lazygit python3
    brew install --cask font-jetbrains-mono-nerd-font
    success "Dipendenze installate"
    install_hermes
    install_rust
    install_tree_sitter_cli
    install_neorex
    install_manual termicons "$TERMICONS_URL"
    install_rex
}

stow_packages() {
    local packages=("$@")
    info "Stowing: ${packages[*]}"
    cd "$DOTFILES_DIR"
    stow --target="$HOME" "${packages[@]}"
    success "Symlink creati"
}

# Rex non legge aspetto e input da init.lua: sono preferenze dell'app (Rex Beta 0.1.0, build 1541).
# Scrive solo queste, mai lo stato di sessioni e connessioni salvato nello stesso plist.
configure_rex() {
    info "Configurazione Rex..."
    "$REX_CLI" config check
    "$REX_CLI" terminfo setup
    # Il tema richiede l'app aperta: se manca, fallisce prima di toccare le preferenze.
    "$REX_CLI" "do" client.theme.import path="$DOTFILES_DIR/rex/.config/rex/themes/rose-pine-moon" \
        || die "Import del tema fallito: apri Rex e rilancia il bootstrap."
    defaults write "$REX_PREFS" Workspace.terminalFontName -string "JetBrainsMono Nerd Font"
    defaults write "$REX_PREFS" Workspace.terminalFallbackFontNames -array termicons
    defaults write "$REX_PREFS" Workspace.terminalFontPointSize -float 15
    defaults write "$REX_PREFS" Workspace.terminalCellHeightPercent -float 35
    defaults write "$REX_PREFS" Workspace.terminalAllowsLigatures -bool true
    defaults write "$REX_PREFS" Workspace.terminalCursorStyle -string block
    defaults write "$REX_PREFS" Workspace.terminalCursorStyleForced -bool false
    defaults write "$REX_PREFS" Workspace.terminalOptionKeyBehavior -string left
    defaults write "$REX_PREFS" Workspace.terminalCopyOnSelect -bool true
    "$REX_CLI" config reload
    success "Rex configurato (riaprilo se le preferenze non si aggiornano)"
}

[[ -z "$PROFILE" ]] && usage

case "$PROFILE" in
    macos)
        install_macos
        stow_packages nvim fish rex fastfetch hermes starship vim
        configure_rex
        ;;
    *)
        usage
        ;;
esac

success "=== Bootstrap '$PROFILE' completato ==="
