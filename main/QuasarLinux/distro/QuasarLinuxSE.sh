#!/usr/bin/env sh

export VERSION="1.1"
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'
export BRIGHT_WHITE='\033[1;97m$*\033[0m'


logo() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                                  ║
║  ███████╗ ██╗   ██╗ █████╗ ███████╗ █████╗ ██████╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ███████╗███████╗ ║
║  ██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗   ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██╔════╝██╔════╝ ║
║  ██║   ██║██║   ██║███████║███████╗███████║██████╔╝   ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ███████╗█████╗   ║
║  ██║▄▄ ██║██║   ██║██╔══██║╚════██║██╔══██║██╔══██╗   ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ╚════██║██╔══╝   ║
║  ╚██████╔╝╚██████╔╝██║  ██║███████║██║  ██║██║  ██║   ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ███████║███████╗ ║
║   ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚══════╝╚══════╝ ║
║                                                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
EOF
}

base_system_package() {
    _ "Installing base system..."
    basestrap /mnt terminus-font iptables base base-devel \
        mkinitcpio openrc dbus dbus-openrc elogind-openrc linux-firmware dialog \
        acpid flatpak acpid-openrc chrony-openrc dash chrony linux-api-headers \
        rsync lib32-udev networkmanager networkmanager-openrc pacman-static \
        linux linux-headers
    fast-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo



main() {
    /installer/modules/parted.sh
    base_system
}
