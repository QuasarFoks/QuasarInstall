#!/bin/bash

#   QuasarLinux
#   default prefix
#   by QuasarFoks

cat << EOF
========================
== Use Default prefix ==
========================

EOF


gpu_info=$(lspci -nn | grep -i 'VGA\|3D\|Display' | head -1)

echo "install (mesa, vesa, fbdev)..."

chroot /mnt pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-vesa xf86-video-fbdev


if echo "$gpu_info" | grep -qi "AMD"; then
    echo "$GPU_DETECT_AMD"
    chroot /mnt pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver mesa-vdpau

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
./default.de.sh
echo "$INSTALL_COMPLETED"
