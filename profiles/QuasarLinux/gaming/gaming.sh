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

chroot /mnt pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-vesa xf86-video-fbdev

# Определяем и устанавливаем специфичные драйверы
if echo "$gpu_info" | grep -qi "AMD"; then

    echo "AMD graphics card detected"

    chroot /mnt pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver mesa-vdpau

elif echo "$gpu_info" | grep -qi "Intel"; then

    echo "Intel graphics card detected"

    chroot /mnt pacman -S --noconfirm xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver

elif echo "$gpu_info" | grep -qi "NVIDIA"; then

    echo "NVIDIA graphics card detected"
    echo "!!! NVIDIA drivers may be unstable and have issues with Wayland !!!"

    sleep 5
    chroot /mnt pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

elif echo "$gpu_info" | grep -qi "QXL"; then

    echo "QXL virtual graphics card detected (QEMU)"

    chroot /mnt pacman -S --noconfirm xf86-video-qxl qemu-guest-agent qemu-guest-agent-openrc
    chroot /mnt rc-update add qemu-guest-agent default

elif echo "$gpu_info" | grep -qi "Virtio"; then

    echo "Virtio virtual graphics card detected (QEMU/KVM)"

    # Virtio-GPU использует стандартные mesa/vulkan, но может использовать Venus
    chroot /mnt pacman -S --noconfirm vulkan-virtio lib32-vulkan-virtio qemu-guest-agent qemu-guest-agent-openrc
    chroot /mnt rc-update add qemu-guest-agent default

elif echo "$gpu_info" | grep -qi "VMware"; then
    echo "VMware virtual graphics card detected"

    chroot /mnt pacman -S --noconfirm xf86-video-vmware xlibre-xf86-video-vmware xlibre-xf86-input-vmmouse xf86-input-vmmouse
else

    echo "Graphics card not detected — using only fallback (vesa/fbdev)"
    echo "Performance will be low!"

    sleep 3
fi


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

