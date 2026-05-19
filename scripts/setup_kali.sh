#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

get_kali_year() {
    grep "VERSION_ID" /etc/os-release 2>/dev/null | cut -d'"' -f2 | cut -d'.' -f1
}

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

# Rimuove pacchetti non-t64 che conflittano con la transizione Debian 2026
remove_old_t64_conflicts() {
    print_status "Removing old non-t64 packages that conflict with 2026 transition..."
    local OLD_PKGS=(
        libgtk-3-0
        libglib2.0-0
        libgnutls30
        libreadline8
        libcups2
        libpsl5
        libhogweed6
        libcurl3-gnutls
        libtirpc3
        libxerces-c3.2
        libtumbler-1-0
        libgnutls-dane0
        kali-wallpapers-2023
    )
    for pkg in "${OLD_PKGS[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            sudo dpkg -r --force-depends "$pkg" 2>/dev/null && \
                print_status "Removed $pkg" || true
        fi
    done
}

# Rimuove plugin NM-VPN: systemd vecchio non supporta 'u!' in sysusers.d
remove_nm_vpn_plugins() {
    print_status "Removing NM VPN plugins (incompatible with old systemd)..."
    sudo apt remove --purge -y \
        network-manager-openvpn \
        network-manager-openconnect \
        network-manager-openvpn-gnome \
        network-manager-openconnect-gnome 2>/dev/null || true
}

reinstall_nm_vpn_plugins() {
    print_status "Reinstalling NM VPN plugins (systemd now updated)..."
    sudo apt install -y \
        network-manager-openvpn \
        network-manager-openconnect \
        network-manager-openvpn-gnome \
        network-manager-openconnect-gnome 2>/dev/null || true
}

upgrade_old_kali() {
    print_status "Old Kali detected — running migration-aware upgrade..."

    remove_nm_vpn_plugins
    remove_old_t64_conflicts

    sudo apt update

    local attempts=0
    until sudo apt-get -o Dpkg::Options::="--force-overwrite" full-upgrade -y; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 5 ]; then
            print_error "Full upgrade failed after $attempts attempts"
            break
        fi
        print_status "Upgrade attempt $attempts failed, running fix-broken..."
        sudo apt-get -o Dpkg::Options::="--force-overwrite" --fix-broken install -y || true
    done

    sudo apt-get -o Dpkg::Options::="--force-overwrite" --fix-broken install -y || true

    reinstall_nm_vpn_plugins

    print_success "Migration upgrade completed"
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

# Fix display nero su UTM/virtio-gpu: disabilita compositor xfwm4
setup_display_utm() {
    print_status "Configuring display for UTM (disabling compositor)..."

    sudo tee -a /etc/lightdm/lightdm.conf > /dev/null << EOF

[LightDM]
logind-check-graphical=true

[Seat:*]
greeter-session=lightdm-gtk-greeter
EOF

    # Disabilita compositor per tutti gli utenti
    for home_dir in /root /home/*; do
        if [ -d "$home_dir" ]; then
            mkdir -p "$home_dir/.config/xfce4/xfwm4"
            cat > "$home_dir/.config/xfce4/xfwm4/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF
        fi
    done
}

setup_ssh() {
    print_status "Installing and enabling SSH server..."
    sudo apt install -y openssh-server 2>/dev/null || true
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo systemctl enable ssh
    sudo systemctl start ssh
}

main_setup() {
    echo -e "${GREEN}=== Kali Linux Basic Setup Script ===${NC}"

    local kali_year
    kali_year=$(get_kali_year)
    print_status "Detected Kali version year: ${kali_year:-unknown}"

    setup_gpg_keys

    if [ -n "$kali_year" ] && [ "$kali_year" -lt 2025 ] 2>/dev/null; then
        print_status "Old Kali (${kali_year}) detected — migration mode"
        upgrade_old_kali
    else
        upgrade_current_kali
    fi

    setup_keyboard
    setup_input
    setup_display_utm
    setup_ssh

    print_status "Setting Europe/Rome timezone..."
    sudo timedatectl set-timezone Europe/Rome

    sudo apt autoremove -y
    sudo updatedb 2>/dev/null || true

    print_success "=== Setup completed ==="
    echo -e "${YELLOW}Keyboard: Italian Apple | Timezone: Europe/Rome | Natural scroll + scroll speed 3.0: enabled${NC}"
    echo -e "${YELLOW}SSH: enabled | Display: compositor disabled for UTM${NC}"
    echo -e "${GREEN}Reboot recommended.${NC}"
}

main_setup
