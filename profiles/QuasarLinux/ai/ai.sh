#!/usr/bin/bash

#   QuasarLinux
#   ai prefix
#   by QuasarFoks

cat << EOF
========================
==    Use AI prefix   ==
========================
EOF

gpu_info=$(lspci -nn | grep -i 'VGA\|3D\|Display' | head -1)

# Установка базовых драйверов везде (fallback + mesa)
if [ "${LANG_MODE:-}" = "ru" ]; then
    echo "Устанавливаю базовую графическую подсистему (mesa, vesa, fbdev)..."
elif [ "${LANG_MODE:-}" = "eu" ]; then
    echo "Installing basic graphics subsystem (mesa, vesa, fbdev)..."
fi
chroot /mnt pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-vesa xf86-video-fbdev

# Определяем и устанавливаем специфичные драйверы
if echo "$gpu_info" | grep -qi "AMD"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена видеокарта AMD"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "AMD graphics card detected"
    fi
    chroot /mnt pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver mesa-vdpau rocm-hip-sdk rocm-opencl-sdk rocm-ml-sdk

elif echo "$gpu_info" | grep -qi "Intel"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена видеокарта Intel"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "Intel graphics card detected"
    fi
    chroot /mnt pacman -S --noconfirm xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver intel-compute-runtime

elif echo "$gpu_info" | grep -qi "NVIDIA"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена видеокарта NVIDIA"
        echo "!!! NVIDIA драйвера могут быть нестабильны и иметь проблемы с Wayland !!!"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "NVIDIA graphics card detected"
        echo "!!! NVIDIA drivers may be unstable and have issues with Wayland !!!"
    fi
    sleep 5
    chroot /mnt pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings cuda cudnn python-pytorch-cuda tensorflow-cuda

elif echo "$gpu_info" | grep -qi "QXL"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена виртуальная видеокарта QXL (QEMU)"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "QXL virtual graphics card detected (QEMU)"
    fi
    echo "AMD/NVIDIA/INTEL only!"

elif echo "$gpu_info" | grep -qi "Virtio"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена виртуальная видеокарта Virtio (QEMU/KVM)"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "Virtio virtual graphics card detected (QEMU/KVM)"
    fi
    # Virtio-GPU использует стандартные mesa/vulkan, но может использовать Venus
    echo "AMD/NVIDIA/INTEL only!"

elif echo "$gpu_info" | grep -qi "VMware"; then
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Обнаружена виртуальная видеокарта VMware"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "VMware virtual graphics card detected"
    fi
    echo "AMD/NVIDIA/INTEL only!"
else
    if [ "${LANG_MODE:-}" = "ru" ]; then
        echo "Видеокарта не определена — используется только fallback (vesa/fbdev)"
        echo "Производительность будет низкой!"
    elif [ "${LANG_MODE:-}" = "eu" ]; then
        echo "Graphics card not detected — using only fallback (vesa/fbdev)"
        echo "Performance will be low!"
    fi
    sleep 3
fi

if [ "${LANG_MODE:-}" = "ru" ]; then
    echo "Установка завершена."
elif [ "${LANG_MODE:-}" = "eu" ]; then
    echo "Installation completed."
fi

chroot /mnt pacman -S python python-pip python-virtualenv python-numpy python-scipy python-matplotlib python-pandas cmake ninja openblas lapack fftw --noconfirm --needed
