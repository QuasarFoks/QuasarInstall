#!/bin/bash

#   QuasarLinux
#   custom prefix
#   by QuasarFoks

cat << EOF
========================
==  Use custom prefix ==
========================

EOF

packages=(
    1 "htop" off
    2 "mc" off
    3 "nano" on
    4 "vim" on
    5 "neovim" off
    6 "ranger" off
    7 "lynx" off
    8 "w3m" off
    9 "curl" on
    10 "wget" on
    11 "git" on
    12 "ncdu" off
    13 "tmux" off
    14 "screen" off
    15 "nmap" off
    16 "irssi" off
    17 "mutt" off
    18 "rtorrent" off
    19 "ffmpeg" off
    20 "unzip" off
    21 "zip" off
    22 "go" off
    23 "qt6" off
    24 "rsync" off
    25 "sysstat" off
    26 "cmus" off
    27 "ncmpcpp" off
    28 "newsboat" off
    29 "fzf" off
    30 "gtk4" off
    31 "gtk3" off
    32 "gtk2" off
    33 "qt5" off
    34 "docker" off
    35 "docker-openrc" off
    36 "gamemode" off
    37 "polkit" off
    38 "x264" on
    39 "x265" on
    40 "openh264" on
    41 "qemu-full" off
    42 "qemu-base" off
    43 "grub-customizer" off
    44 "qbittorrent" off
    45 "qbittorrent-openrc" off
    46 "vlc" off
    47 "gwenview" off
    48 "krita" off
    49 "jdk-openjdk" off
    50 "jre8-openjdk" off
    51 "jre-openjdk" off
    52 "openjdk-src" off
    53 "kdeconnect" off
    54 "virt-manager" off
    55 "libvirt" off
    56 "libvirt-openrc" off
    57 "wireshark-cli" off
    58 "wireshark-qt" off
    59 "cups" off
    60 "cups-openrc" off
    61 "lib32-libcups" off
    62 "apcupsd" off
    63 "apcupsd-openrc" off
    64 "bluez-cups" off
    65 "libcups" off
    66 "libcupsfilters" off
    67 "system-config-printer" off
    68 "bluedevil" off
    69 "bluez" off
    70 "bluez-libs" off
    71 "bluez-qt5" off
    72 "bluez-openrc" off
    73 "gnome-bluetooth-3.0" off
    74 "bluez-utils" off
)

amd_drivers() {
    echo "Select AMD graphics driver:"
    echo "1) 3D amdvlk (AMD Vulkan)"
    echo "2) 3D vulkan-radeon (Mesa Vulkan)"
    echo "3) 2D driver (xf86-video-amdgpu)"
    echo "4) ML/AI ROCm (OpenCL/HIP)"
    echo -n "Your choice (1-4, press Enter for default 2): "
    read -r drivers

    case $drivers in
        1)
            echo "Installing amdvlk..."
            chroot /mnt pacman -S --needed --noconfirm amdvlk lib32-amdvlk
            ;;
        2)
            echo "Installing vulkan-radeon..."
            chroot /mnt pacman -S --needed --noconfirm vulkan-radeon libva-mesa-driver mesa-vdpau mesa
            chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-radeon
            ;;
        3)
            echo "Installing xf86-video-amdgpu..."
            chroot /mnt pacman -S --needed --noconfirm xf86-video-amdgpu
            ;;
        4)
            echo "Installing ROCm..."
            chroot /mnt pacman -S --needed --noconfirm rocm-opencl-runtime clinfo rocm-hip-sdk
            ;;
        *)
            echo "Using default (vulkan-radeon)..."
            chroot /mnt pacman -S --needed --noconfirm vulkan-radeon libva-mesa-driver mesa-vdpau mesa
            chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-radeon
            ;;
    esac
}

video_drivers() {
    gpu_info=$(lspci -nn | grep -i 'VGA\|3D\|Display' | head -1)

    echo "Installing basic graphics drivers (mesa, vesa, fbdev)..."

    chroot /mnt pacman -S --needed --noconfirm mesa vulkan-icd-loader xf86-video-vesa xf86-video-fbdev
    chroot /mnt pacman -S --needed --noconfirm lib32-mesa lib32-vulkan-icd-loader

    if echo "$gpu_info" | grep -qi "AMD"; then
        echo "$GPU_DETECT_AMD"
        amd_drivers

    elif echo "$gpu_info" | grep -qi "Intel"; then
        echo "$GPU_DETECT_INTEL"
        chroot /mnt pacman -S --needed --noconfirm xf86-video-intel vulkan-intel intel-media-driver libva-intel-driver
        chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-intel

    elif echo "$gpu_info" | grep -qi "NVIDIA"; then
        echo "$GPU_DETECT_NVIDIA"
        echo "$GPU_NVIDIA_WARNING"
        sleep 5
        chroot /mnt pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings
        chroot /mnt pacman -S --needed --noconfirm lib32-nvidia-utils

    elif echo "$gpu_info" | grep -qi "QXL"; then
        echo "$GPU_DETECT_QXL"
        chroot /mnt pacman -S --noconfirm xf86-video-qxl qemu-guest-agent qemu-guest-agent-openrc
        chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "Virtio"; then
        echo "$GPU_DETECT_VIRTIO"
        chroot /mnt pacman -S --needed --noconfirm vulkan-virtio qemu-guest-agent qemu-guest-agent-openrc
        chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-virtio
        chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "VMware"; then
        echo "$GPU_DETECT_VMWARE"
        chroot /mnt pacman -S --needed --noconfirm xf86-video-vmware xlibre-xf86-video-vmware xlibre-xf86-input-vmmouse xf86-input-vmmouse
    else
        echo "$GPU_NOT_DETECTED"
        echo "$GPU_LOW_PERFORMANCE"
        sleep 3
    fi

    echo "$INSTALL_COMPLETED"
}

custom_install() {
    # Проверяем наличие dialog
    if ! command -v dialog &> /dev/null; then
        echo "Installing dialog for package selection..."
        pacman -S --noconfirm dialog || {
            echo "Failed to install dialog. Using text-based selection..."
            text_based_selection
            return
        }
    fi

    # Выбор пакетов через dialog
    selected=$(dialog --checklist "$SELECTED_PACK" 45 80 5 "${packages[@]}" 3>&1 1>&2 2>&3 3>&-)

    if [ $? -ne 0 ]; then
        echo "Selection cancelled."
        return
    fi

    clear

    # Формируем список имён пакетов
    install_list=()
    for num in $selected; do
        num=$(echo "$num" | tr -d '"')
        # Находим индекс пакета в массиве (индексы 1, 4, 7, ...)
        index=$(( (num - 1) * 3 + 1 ))
        if [ $index -ge 0 ] && [ $index -lt ${#packages[@]} ]; then
            pkg_name=${packages[$index]}
            install_list+=("$pkg_name")
        fi
    done

    # Устанавливаем выбранные пакеты + NetworkManager
    echo "Installing NetworkManager..."
    chroot /mnt pacman -S --needed --noconfirm networkmanager networkmanager-openrc
    chroot /mnt rc-update add NetworkManager default

    if [ ${#install_list[@]} -gt 0 ]; then
        echo "Installing selected packages: ${install_list[*]}"
        chroot /mnt pacman -S --needed --noconfirm "${install_list[@]}"
    else
        echo "No additional packages selected."
    fi

    # Обработка OpenRC сервисов для выбранных пакетов
    for pkg in "${install_list[@]}"; do
        case $pkg in
            "qbittorrent-openrc")
                chroot /mnt rc-update add qbittorrent default 2>/dev/null && \
                    echo "✓ qbittorrent added to autostart" || \
                    echo "⚠ qbittorrent service not found"
                ;;
            "libvirt-openrc")
                chroot /mnt rc-update add libvirtd default 2>/dev/null && \
                    echo "✓ libvirtd added to autostart" || \
                    echo "⚠ libvirtd service not found"
                ;;
            "docker-openrc")
                chroot /mnt rc-update add docker default 2>/dev/null && \
                    echo "✓ docker added to autostart" || \
                    echo "⚠ docker service not found"
                ;;
            "cups-openrc")
                chroot /mnt rc-update add cupsd default 2>/dev/null && \
                    echo "✓ cupsd added to autostart" || \
                    echo "⚠ cupsd service not found"
                ;;
            "apcupsd-openrc")
                chroot /mnt rc-update add apcupsd default 2>/dev/null && \
                    echo "✓ apcupsd added to autostart" || \
                    echo "⚠ apcupsd service not found"
                ;;
            "bluez-openrc")
                chroot /mnt rc-update add bluetooth default 2>/dev/null && \
                    echo "✓ bluetooth added to autostart" || \
                    echo "⚠ bluetooth service not found"
                ;;
            "polkit")
                chroot /mnt rc-update add polkit default 2>/dev/null && \
                    echo "✓ polkit added to autostart" || \
                    echo "⚠ polkit service not found"
                ;;
        esac
    done
}

text_based_selection() {
    echo "=== Text-based Package Selection ==="
    echo "Enter package numbers separated by spaces (e.g., 1 3 9 10):"
    echo

    # Отображаем список пакетов
    for ((i=0; i<${#packages[@]}; i+=3)); do
        num=$((i/3+1))
        name=${packages[$i+1]}
        default=${packages[$i+2]}
        echo "$num) $name [default: $default]"
    done

    echo
    echo -n "Your selection: "
    read -r selection

    install_list=()
    for num in $selection; do
        if [[ $num =~ ^[0-9]+$ ]] && [ $num -ge 1 ] && [ $num -le $((${#packages[@]}/3)) ]; then
            index=$(( (num - 1) * 3 + 1 ))
            pkg_name=${packages[$index]}
            install_list+=("$pkg_name")
        fi
    done

    echo "Selected: ${install_list[*]}"

    # Устанавливаем выбранные пакеты
    if [ ${#install_list[@]} -gt 0 ]; then
        chroot /mnt pacman -S --needed --noconfirm "${install_list[@]}"
    fi
}

install_packs() {
    local USERLAND="/installer/modules/userland"

    if [ -d "$USERLAND" ]; then
        echo "Running userland configuration modules..."

        # Используем конфигурационные скрипты вместо установочных
        [ -f "$USERLAND/de_config" ] && {
            echo "Running DE configuration..."
            "$USERLAND"/de_config
        }

        [ -f "$USERLAND/audio_config" ] && {
            echo "Running audio configuration..."
            "$USERLAND"/audio_config
        }

        [ -f "$USERLAND/office_config" ] && {
            echo "Running office configuration..."
            "$USERLAND"/office_config
        }

        [ -f "$USERLAND/browser_config" ] && {
            echo "Running browser configuration..."
            "$USERLAND"/browser_config
        }

        [ -f "$USERLAND/wine_config" ] && {
            echo "Running wine configuration..."
            "$USERLAND"/wine_config
        }
    else
        echo "Userland directory not found: $USERLAND"
        echo "Skipping userland configuration..."
    fi
}

main() {
    echo "=== Starting Custom Installation ==="

    # Проверяем, что мы в chroot или система установлена в /mnt
    if [ ! -d "/mnt/bin" ] && [ ! -d "/mnt/usr/bin" ]; then
        echo "Error: /mnt doesn't appear to be a mounted root filesystem!"
        echo "Make sure the system is installed in /mnt before running this script."
        exit 1
    fi

    # Проверяем интернет соединение
    echo "Checking internet connection..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        echo "Warning: No internet connection detected!"
        echo "Some operations may fail."
        sleep 3
    fi

    video_drivers
    custom_install
    install_packs

    echo "========================================"
    echo "Custom installation completed!"
    echo "You may want to reboot to apply changes."
    echo "========================================"
}

# Запуск основной функции
main
