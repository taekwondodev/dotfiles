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

usage() {
    echo "Usage: $0 [macos|linux|server]"
    echo ""
    echo "  macos   — nvim fish ghostty claude starship vim (brew)"
    echo "  linux   — nvim fish ghostty starship vim (apt/dnf)"
    echo "  server  — vim only"
    exit 1
}

detect_pkg_manager() {
    if command -v apt &>/dev/null;    then echo "apt"
    elif command -v dnf &>/dev/null;  then echo "dnf"
    else die "Package manager non supportato. Aggiungi il tuo in scripts/bootstrap.sh."
    fi
}

install_tree_sitter_cli() {
    if command -v tree-sitter &>/dev/null; then
        success "tree-sitter-cli già installato"
        return
    fi
    if ! command -v cargo &>/dev/null; then
        info "Cargo non trovato. Installazione Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    info "Installazione tree-sitter-cli..."
    cargo install tree-sitter-cli
}

install_font_linux() {
    info "Installazione JetBrainsMono Nerd Font..."
    local tmp
    tmp=$(mktemp -d)
    curl -OL --output-dir "$tmp" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    mkdir -p ~/.local/share/fonts
    tar -xf "$tmp/JetBrainsMono.tar.xz" -C ~/.local/share/fonts
    fc-cache -fv
    rm -rf "$tmp"
    success "Font installato"
}

install_termicons() {
    info "termicons richiede installazione manuale."
    info "Apertura: $TERMICONS_URL"
    if command -v xdg-open &>/dev/null; then
        xdg-open "$TERMICONS_URL" 2>/dev/null || true
    elif command -v open &>/dev/null; then
        open "$TERMICONS_URL"
    else
        echo -e "${YELLOW}Apri manualmente:${NC} $TERMICONS_URL"
    fi
    read -rp "$(echo -e "${YELLOW}[WAIT]${NC} Premi Enter quando hai installato termicons...")"
}

install_macos() {
    command -v brew &>/dev/null || die "Homebrew non trovato: https://brew.sh"
    info "Installazione dipendenze macOS..."
    brew install stow git starship neovim fd
    brew install --cask font-jetbrains-mono-nerd-font
    success "Dipendenze installate"
    install_tree_sitter_cli
    install_termicons
}

install_linux() {
    local pm
    pm=$(detect_pkg_manager)
    info "Package manager rilevato: $pm"

    info "Installazione dipendenze Linux..."
    case "$pm" in
        apt)
            sudo apt update
            sudo apt install -y stow git neovim fd-find
            ;;
        dnf)
            sudo dnf install -y stow git neovim fd-find
            ;;
    esac

    if ! command -v starship &>/dev/null; then
        info "Installazione Starship..."
        curl -sS https://starship.rs/install.sh | sh
    fi

    success "Dipendenze installate"
    install_font_linux
    install_tree_sitter_cli
    install_termicons
}

stow_packages() {
    local packages=("$@")
    info "Stowing: ${packages[*]}"
    cd "$DOTFILES_DIR"
    stow "${packages[@]}"
    success "Symlink creati"
}

link_server() {
    info "Creazione symlink server (no stow)..."
    ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
    success "Symlink creati"
}

[[ -z "$PROFILE" ]] && usage

case "$PROFILE" in
    macos)
        install_macos
        stow_packages nvim fish ghostty claude starship vim
        ;;
    linux)
        install_linux
        stow_packages nvim fish ghostty starship vim
        ;;
    server)
        link_server
        ;;
    *)
        usage
        ;;
esac

success "=== Bootstrap '$PROFILE' completato ==="
