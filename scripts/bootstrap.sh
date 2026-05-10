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

install_macos() {
    command -v brew &>/dev/null || die "Homebrew non trovato: https://brew.sh"
    info "Installazione dipendenze macOS..."
    brew install stow git starship neovim fd
    brew install --cask font-jetbrains-mono-nerd-font
    success "Dipendenze installate"
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
}

stow_packages() {
    local packages=("$@")
    info "Stowing: ${packages[*]}"
    cd "$DOTFILES_DIR"
    stow "${packages[@]}"
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
        stow_packages vim
        ;;
    *)
        usage
        ;;
esac

success "=== Bootstrap '$PROFILE' completato ==="
