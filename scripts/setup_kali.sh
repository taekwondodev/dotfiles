#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

setup_gpg_keys() {
    print_status "Setting up Kali GPG keys..."
    sudo rm -f /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
    sudo rm -f /etc/apt/trusted.gpg.d/kali-archive-keyring.asc
    curl -sSL https://archive.kali.org/archive-key.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg > /dev/null
    sudo chmod 644 /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
    sudo tee /etc/apt/sources.list > /dev/null << EOF
deb http://http.kali.org/kali kali-rolling main non-free contrib
deb-src http://http.kali.org/kali kali-rolling main non-free contrib
EOF
}

upgrade_current_kali() {
    print_status "Updating and upgrading system..."
    sudo apt update
    if sudo apt full-upgrade -y --allow-downgrades; then
        print_success "System updated successfully"
    else
        print_error "APT upgrade failed"
    fi
}

setup_keyboard() {
    print_status "Configuring keyboard layout..."
    sudo tee /etc/default/keyboard > /dev/null << EOF
XKBMODEL="apple"
XKBLAYOUT="it"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

    # Keyboard persistente anche in TTY
    if command -v localectl &>/dev/null; then
        sudo localectl set-keymap it 2>/dev/null || true
    fi
    echo 'KEYMAP=it' | sudo tee /etc/vconsole.conf > /dev/null 2>/dev/null || true

    setxkbmap it -model apple 2>/dev/null || true
}

setup_input() {
    print_status "Configuring natural scroll and scroll speed..."
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/40-libinput.conf > /dev/null << EOF
Section "InputClass"
    Identifier "libinput pointer catchall"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "NaturalScrolling" "true"
    Option "ScrollFactor" "3.0"
EndSection
EOF
}


main_setup() {
    echo -e "${GREEN}=== Kali Linux Basic Setup Script ===${NC}"

    setup_gpg_keys
    upgrade_current_kali

    setup_keyboard
    setup_input

    print_status "Setting Europe/Rome timezone..."
    sudo timedatectl set-timezone Europe/Rome

    sudo apt autoremove -y
    sudo updatedb 2>/dev/null || true

    print_success "=== Setup completed ==="
    echo -e "${YELLOW}Keyboard: Italian Apple | Timezone: Europe/Rome | Natural scroll + scroll speed 3.0: enabled${NC}"
    echo -e "${GREEN}Reboot recommended.${NC}"
}

main_setup
