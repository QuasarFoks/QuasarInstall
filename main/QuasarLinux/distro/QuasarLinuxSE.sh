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
installsys() {
     basestrap /mnt "$@"
}

base_system_package() {
    _ "Installing base system..."
    installsys terminus-font iptables  \
        mkinitcpio openrc dbus dbus-openrc elogind-openrc linux-firmware dialog \
        acpid flatpak acpid-openrc chrony-openrc dash chrony linux-api-headers \
        rsync lib32-udev networkmanager networkmanager-openrc pacman-static \
        iwd iwd-openrc acl artix-cgroups artix-keyring artix-mirrorlist attr audit autoconf automake \
        bash binutils bison boost-libs brotli bzip2 ca-certificates ca-certificates-mozilla \
        ca-certificates-utils coreutils cpio curl db5.3 dbus dbus-openrc debugedit \
        diffutils e2fsprogs elfutils elogind elogind-openrc esysusers etmpfiles expat \
        fakeroot file filesystem findutils flex gawk gc gcc gcc-libs \
        gdb gdb-common gdbm gettext glib2 glibc gmp gnulib-l10n \
        gnupg gnutls gpgme grep groff guile gzip hwdata \
        iana-etc icu iproute2 iptables iputils jansson json-c kbd \
        kexec-tools keyutils kmod krb5 leancrypto libarchive libasan libassuan \
        libatomic libbpf libcap libcap-ng libelf libelogind libevent libffi \
        libgcc libgcrypt libgfortran libgomp libgpg-error libhwasan libidn2 libisl \
        libksba libldap liblsan libmakepkg-dropins libmnl libmpc libnetfilter_conntrack libnfnetlink \
        libnftnl libnghttp2 libnghttp3 libngtcp2 libnl libnsl libobjc libp11-kit \
        libpcap libpsl libquadmath libsasl libseccomp libsecret libssh2 libstdc++ \
        libsysprof-capture libtasn1 libtirpc libtool libtsan libubsan libudev libunistring \
        libusb libutempter libverto libxcrypt libxml2 licenses linux-api-headers lmdb \
        lz4 m4 make mpdecimal mpfr ncurses nettle nftables \
        npth openssl p11-kit pam pambase patch pciutils \
        pcre2 perl pinentry pkgconf procps-ng psmisc python readline \
        sed shadow source-highlight sqlite sudo tar texinfo tpm2-tss \
        tzdata udev util-linux util-linux-libs which xxhash xz zlib \
        zstd
    fast-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    installsys plasma \
    konsole \
    dolphin \
    kate \
    gwenview \
    sddm \
    sddm-openrc \
    kcalc \
    wayland \
    seatd \
    ark \
    xf86-input-wacom xrandr \
    xorg-server \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    partitionmanager   \
    kdeconnect \
    kio-gdrive \
    p7zip \
    unrar \
    tar  \
    tesseract-data \
    tesseract \
    maim \
    xclip

    if echo "$gpu_info" | grep -qi "AMD"; then
        echo "$GPU_DETECT_AMD"
        installsys vulkan-radeon libva-mesa-driver mesa-vdpau mesa
        installsys lib32-vulkan-radeon

    elif echo "$gpu_info" | grep -qi "Intel"; then
        echo "$GPU_DETECT_INTEL"
        installsys xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver

    elif echo "$gpu_info" | grep -qi "NVIDIA"; then
        echo "$GPU_DETECT_NVIDIA"
        echo "$GPU_NVIDIA_WARNING"
        sleep 2
        installsys nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

    elif echo "$gpu_info" | grep -qi "QXL"; then
        echo "$GPU_DETECT_QXL"
        installsys xf86-video-qxl qemu-guest-agent qemu-guest-agent-openrc
        fast-chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "Virtio"; then
        echo "$GPU_DETECT_VIRTIO"
        # Virtio-GPU использует стандартные mesa/vulkan, но может использовать Venus
        installsys vulkan-virtio  qemu-guest-agent qemu-guest-agent-openrc
        installsys lib32-vulkan-virtio || true
        fast-chroot /mnt rc-update add qemu-guest-agent default

    elif echo "$gpu_info" | grep -qi "VMware"; then
        echo "$GPU_DETECT_VMWARE"
        installsys xf86-video-vmware xlibre-xf86-video-vmware xlibre-xf86-input-vmmouse xf86-input-vmmouse
    else
        echo "$GPU_NOT_DETECTED"
        echo "$GPU_LOW_PERFORMANCE"

    fi
}
config_system() {
    echo "Настройка SDDM..."
    chroot /mnt groupadd -f sddm
    chroot /mnt useradd -r -g sddm -s /usr/bin/nologin -d /var/lib/sddm sddm 2>/dev/null || true
    chroot /mnt mkdir -p /var/lib/sddm /var/run/sddm
    chroot /mnt chown sddm:sddm /var/lib/sddm /var/run/sddm
    chroot /mnt chmod 0755 /var/lib/sddm /var/run/sddm
    chroot /mnt usermod -aG seat,video,input sddm || true
    chroot /mnt usermod -aG video,input sddm || true
    chroot /mnt rc-update add sddm default
}


main() {
    /installer/modules/parted.sh
    base_system
    config_system
}
