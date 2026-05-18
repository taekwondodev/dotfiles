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

main_setup() {
    echo -e "${GREEN}=== Kali Linux Basic Setup Script ===${NC}"

    setup_gpg_keys

    print_status "Updating and upgrading system..."
    sudo apt update
    if sudo apt full-upgrade -y --allow-downgrades; then
        print_success "System updated successfully"
    else
        print_error "APT upgrade failed"
    fi

    print_status "Configuring keyboard layout..."
    sudo tee /etc/default/keyboard > /dev/null << EOF
XKBMODEL="apple"
XKBLAYOUT="it"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
    setxkbmap it -model apple

    print_status "Enabling natural scroll..."
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/40-libinput.conf > /dev/null << EOF
Section "InputClass"
    Identifier "libinput pointer catchall"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "NaturalScrolling" "true"
EndSection
EOF

    print_status "Setting Europe/Rome timezone..."
    sudo timedatectl set-timezone Europe/Rome

    sudo apt autoremove -y
    sudo updatedb

    print_success "=== Setup completed ==="
    echo -e "${YELLOW}Keyboard: Italian Apple | Timezone: Europe/Rome | Natural scroll: enabled${NC}"
}

main_setup
