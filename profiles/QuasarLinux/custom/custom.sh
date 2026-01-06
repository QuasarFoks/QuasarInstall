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
    drivers=$(dialog --title "Select kernel" --menu "amd drivers" 12 50 5 \
    1 "3D amdvlk" \
    2 "3D vulkan-radeon" \
    3 "2D driver" \
    4 "ML/AI ROMc"
    3>&1 1>&2 2>&3 3>&-)
    case $driver in
        1) chroot /mnt pacman -S ---needed --noconfirm amdvlk lib32-amdvlk  ;;
        2) chroot /mnt pacman -S ---needed --noconfirm vulkan-radeon  lib32-vulkan-radeon libva-mesa-driver mesa-vdpau mesa ;;
        3) chroot /mnt pacman -S ---needed --noconfirm xf86-video-amdgpu ;;
        4) chroot /mnt pacman -S ---needed --noconfirm rocm-opencl-runtime clinfo rocm-opencl-runtime rocm-hip-sdk ;;
        *) exit 0 ;;
    esac


}
video_drivers() {
    gpu_info=$(lspci -nn | grep -i 'VGA\|3D\|Display' | head -1)

    echo "install (mesa, vesa, fbdev)..."

    chroot /mnt pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-vesa xf86-video-fbdev


    if echo "$gpu_info" | grep -qi "AMD"; then
        echo "$GPU_DETECT_AMD"
        amd_drivers

    elif echo "$gpu_info" | grep -qi "Intel"; then
        echo "$GPU_DETECT_INTEL"
        chroot /mnt pacman -S --noconfirm xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver

    elif echo "$gpu_info" | grep -qi "NVIDIA"; then
        echo "$GPU_DETECT_NVIDIA"
        echo "$GPU_NVIDIA_WARNING"
        sleep 5
        chroot /mnt pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

    elif echo "$gpu_info" | grep -qi "QXL"; then
        echo "$GPU_DETECT_QXL"
        chroot /mnt pacman -S --noconfirm xf86-video-qxl qemu-guest-agent qemu-guest-agent-openrc
        chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "Virtio"; then
        echo "$GPU_DETECT_VIRTIO"
        # Virtio-GPU использует стандартные mesa/vulkan, но может использовать Venus
        chroot /mnt pacman -S --noconfirm vulkan-virtio lib32-vulkan-virtio qemu-guest-agent qemu-guest-agent-openrc
        chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "VMware"; then
        echo "$GPU_DETECT_VMWARE"
        chroot /mnt pacman -S --noconfirm xf86-video-vmware xlibre-xf86-video-vmware xlibre-xf86-input-vmmouse xf86-input-vmmouse
    else
        echo "$GPU_NOT_DETECTED"
        echo "$GPU_LOW_PERFORMANCE"
        sleep 3
    fi

    echo "$INSTALL_COMPLETED"


}

custom_install() {
    # Выбор пакетов через dialog
    selected=$(dialog --checklist "$SELECTED_PACK" 45 50 5 "${packages[@]}" 3>&1 1>&2 2>&3 3>&-)

    clear

    # Формируем список имён пакетов
    install_list=()
    for num in $selected; do
        num=$(echo "$num" | tr -d '"')
        pkg_name=${packages[$((num * 3 - 2))]}
        install_list+=("$pkg_name")
    done

    # Устанавливаем выбранные пакеты + NetworkManager и его OpenRC-интеграцию
    if [ ${#install_list[@]} -gt 0 ]; then
        chroot /mnt pacman -S --noconfirm "${install_list[@]}" networkmanager networkmanager-openrc
    else
        chroot /mnt pacman -S --noconfirm networkmanager networkmanager-openrc
    fi

    chroot /mnt rc-update add NetworkManager default

    # Обработка OpenRC сервисов для выбранных пакетов
    for pkg in "${install_list[@]}"; do
        case $pkg in
            "qbittorrent-openrc")
                chroot /mnt rc-update add qbittorrent default && \
                    echo "qbittorrent успешно добавлен в автозагрузку" || \
                    echo "пропускаем qbittorrent..."
                ;;
            "libvirt-openrc")
                chroot /mnt rc-update add libvirtd default && \
                    echo "libvirtd успешно добавлен в автозагрузку" || \
                    echo "пропускаем libvirtd..."
                ;;
            "docker-openrc")
                chroot /mnt rc-update add docker default && \
                    echo "docker успешно добавлен в автозагрузку" || \
                    echo "пропускаем docker..."
                ;;
            "cups-openrc")
                chroot /mnt rc-update add cupsd default && \
                    echo "cupsd успешно добавлен в автозагрузку" || \
                    echo "пропускаем cupsd..."
                ;;
            "apcupsd-openrc")
                chroot /mnt rc-update add apcupsd default && \
                    echo "apcupsd успешно добавлен в автозагрузку" || \
                    echo "пропускаем apcupsd..."
                ;;
            "bluez-openrc")
                chroot /mnt rc-update add bluetooth default && \
                    echo "bluetooth успешно добавлен в автозагрузку" || \
                    echo "пропускаем bluetooth..."
                ;;
            "polkit")
                chroot /mnt rc-update add polkit default && \
                    echo "polkit успешно добавлен в автозагрузку" || \
                    echo "пропускаем polkit..."
                ;;
        esac
    done
}
main() {

}
main
