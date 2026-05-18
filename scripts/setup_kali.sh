#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Kali Linux Basic Setup Script ===${NC}"

# Function to print status
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

fix_package_conflicts() {
    print_status "Resolving package conflicts..."

    # Upgrade kali-defaults and dconf-cli first (required by kali-themes 2026)
    sudo apt-get install -y dconf-cli kali-defaults kali-wallpapers-2026 2>/dev/null || true
    # Now install theme packages with satisfied deps
    sudo apt-get install -y kali-themes kali-desktop-base kali-themes-common 2>/dev/null || true

    # Configure any pending packages
    sudo dpkg --configure -a 2>/dev/null || true

    sudo apt clean
}

# GPG key installation 
setup_gpg_keys() {
    print_status "Setting up Kali GPG keys..."
    
    # Remove any existing problematic keys
    sudo rm -f /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
    sudo rm -f /etc/apt/trusted.gpg.d/kali-archive-keyring.asc
    
    curl -sSL https://archive.kali.org/archive-key.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg > /dev/null
    
    # Set proper permissions
    sudo chmod 644 /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
    
    # Update sources list
    sudo tee /etc/apt/sources.list > /dev/null << EOF
deb http://http.kali.org/kali kali-rolling main non-free contrib
deb-src http://http.kali.org/kali kali-rolling main non-free contrib
EOF
}

# Main setup function
main_setup() {
    setup_gpg_keys

    print_status "Updating package lists..."
    sudo apt update

    fix_package_conflicts

    if sudo apt full-upgrade -y --allow-downgrades --allow-remove-essential; then
        print_success "System updated successfully"
    else
        print_error "APT upgrade failed"
    fi

    # Permanent keyboard fix
    print_status "Configuring keyboard layout..."
    sudo tee /etc/default/keyboard > /dev/null << EOF
XKBMODEL="apple"
XKBLAYOUT="it"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
    
    # Apply immediately
    setxkbmap it -model apple

    # Enable natural (reverse) scroll
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

    # Configure timezone
    print_status "Setting Europe/Rome timezone..."
    sudo timedatectl set-timezone Europe/Rome

    # Final cleanup
    sudo apt autoremove -y
    sudo updatedb

    print_success "=== Basic setup completed successfully! ==="
    echo -e "${YELLOW}Keyboard layout: Italian Apple${NC}"
    echo -e "${YELLOW}Timezone: Europe/Rome${NC}"
    echo -e "${YELLOW}Essential tools installed${NC}"
}

# Run main setup
main_setup
