#!/bin/sh

#   QuasarLinux
#   gaming prefix
#   by QuasarFoks

cat << EOF
========================
==  Use Gaming prefix ==
========================
EOF


gpu_info=$(lspci -nn | grep -i 'VGA\|3D\|Display' | head -1)

# Установка базовых драйверов везде (fallback + mesa)

echo "Installing basic graphics subsystem (mesa, vesa, fbdev)..."

chroot /mnt pacman -S --noconfirm mesa  vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-vesa xf86-video-fbdev
chroot /mnt pacman -S --needed --noconfirm lib32-mesa

# Определяем и устанавливаем специфичные драйверы
video_drivers() {
   if echo "$gpu_info" | grep -qi "AMD"; then

        echo "AMD graphics card detected"

        chroot /mnt pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon  libva-mesa-driver mesa-vdpau
        chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-radeon lib32-mesa

   elif echo "$gpu_info" | grep -qi "Intel"; then
        echo "$GPU_DETECT_INTEL"
        chroot /mnt pacman -S --needed --noconfirm xf86-video-intel vulkan-intel  intel-media-driver libva-intel-driver
        chroot /mnt pacman -S --needed --noconfirm lib32-vulkan-intel

    elif echo "$gpu_info" | grep -qi "NVIDIA"; then
        echo "$GPU_DETECT_NVIDIA"
        echo "$GPU_NVIDIA_WARNING"
        sleep 5
        chroot /mnt pacman -S --needed --noconfirm nvidia-dkms nvidia-utils  nvidia-settings
        chroot /mnt pacman -S --needed --noconfirm lib32-nvidia-utils

    elif echo "$gpu_info" | grep -qi "QXL"; then
        echo "$GPU_DETECT_QXL"
        chroot /mnt pacman -S --noconfirm xf86-video-qxl qemu-guest-agent qemu-guest-agent-openrc
        chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "Virtio"; then
        echo "$GPU_DETECT_VIRTIO"
        # Virtio-GPU использует стандартные mesa/vulkan, но может использовать Venus
        chroot /mnt pacman -S --needed --noconfirm vulkan-virtio  qemu-guest-agent qemu-guest-agent-openrc
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

}
video_drivers
echo "Installation completed."


chroot /mnt pacman -S vulkan-icd-loader  cpupower cpupower-openrc  --noconfirm --needed
chroot /mnt pacman -S lib32-vulkan-icd-loader lib32-glu lib32-libgl lib32-libva --noconfirm
chroot /mnt rc-update add cpupower boot

cat >> /mnt/etc/sysctl.d/99-gaming.conf << 'EOF'
vm.max_map_count = 16777216
fs.file-max = 524288
kernel.pid_max = 4194303
fs.inotify.max_user_watches = 524288

# Уменьшение латентности сети
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr

EOF

cat >> /mnt/etc/conf.d/cpupower << 'EOF'
governor="ondemand"
min_freq="0"
max_freq="0"
EOF
install_packs() {
    local USERLAND="/installer/modules/userland"
    "$USERLAND"/de_install plasma
    "$USERLAND"/audio_install pipewire
    "$USERLAND"/office_install onlyoffice
    "$USERLAND"/browser_install firefox
    "$USERLAND"/wine_install portproton
}

