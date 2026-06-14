#!/bin/bash
set -euo pipefail

# --- gettext init ---
SYSTEM_LANG=${LANG:0:5}
SUPPORTED_LANGS=("de_DE" "en_US" "es_ES" "fr_FR" "it_IT" "ja_JP" "pt_BR" "ru_RU" "tr_TR" "zh_CN")
LANG_FOUND=0
for lang in "${SUPPORTED_LANGS[@]}"; do
    [ "$SYSTEM_LANG" = "$lang" ] && LANG_FOUND=1 && break
done
[ $LANG_FOUND -eq 0 ] && export LANG="en_US.UTF-8" || export LANG="$SYSTEM_LANG.UTF-8"

export TEXTDOMAIN="installer"
export TEXTDOMAINDIR="/usr/local/sdk/global/locale"

if ! command -v gettext &> /dev/null; then
    _() { echo "$1"; }
else
    _() { gettext -s "$1"; }
fi
# --- end gettext init ---

UEFI_MODE=0
[ -d /sys/firmware/efi ] && UEFI_MODE=1
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /dev /mnt/dev
mount --bind /run /mnt/run
root_dev=$(findmnt -n -o SOURCE /mnt)
ROOT_UUID=$(blkid -s UUID -o value "$root_dev")
export ROOT_UUID

mnt_dev=$(findmnt -n -o SOURCE /mnt)
disk_dev=$(lsblk -no PKNAME "$mnt_dev")
DISK="/dev/$disk_dev"
echo "$(_ "Disk detected: ")$DISK"

if [ "$UEFI_MODE" -eq 1 ]; then
    function grub() {
        echo "$(_ "Setting up GRUB for UEFI...")"
        fast-chroot /mnt pacman -S grub os-prober efibootmgr --noconfirm
        fast-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck
        fast-chroot /mnt bash -c 'sed -i "s/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR=\"$GRUB_DISTRIBUTOR_NAME\"/" /etc/default/grub || echo "GRUB_DISTRIBUTOR=\"$GRUB_DISTRIBUTOR_NAME\"" >> /etc/default/grub'
        fast-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        echo "$(_ "GRUB installed for UEFI")"
    }

    function efistub() {
        mount --bind /proc /mnt/proc
        mount --bind /sys /mnt/sys
        mount --bind /dev /mnt/dev
        mount --bind /run /mnt/run
        echo "$(_ "Setting up EFISTUB...")"
        chroot /mnt pacman -S efibootmgr os-prober --noconfirm
        pacman -S efibootmgr --noconfirm
        efibootmgr -b 0000 -B 2>/dev/null || true
        KERNEL=""
        INITRAMFS=""
        if chroot /mnt test -f /boot/vmlinuz-linux; then
            KERNEL="linux"
        elif chroot /mnt test -f /boot/vmlinuz-linux-zen; then
            KERNEL="linux-zen"
        elif chroot /mnt test -f /boot/vmlinuz-linux-lts; then
            KERNEL="linux-lts"
        else
            echo "$(_ "Error: kernel not found")"
            exit 1
        fi
        cp "/mnt/boot/vmlinuz-$KERNEL" "/mnt/boot/efi/vmlinuz-$KERNEL.efi"
        cp "/mnt/boot/initramfs-$KERNEL.img" "/mnt/boot/efi/initramfs-$KERNEL.img"

        efibootmgr -c -d "$DISK" -p 1 -L "QuasarLinux" -l "\\vmlinuz-$KERNEL.efi"  -u "root=UUID=$ROOT_UUID rw initrd=\\initramfs-$KERNEL.img"
        echo "$(_ "EFISTUB configured")"
    }

    function refind() {
        mount --bind /proc /mnt/proc
        mount --bind /sys /mnt/sys
        mount --bind /dev /mnt/dev
        mount --bind /run /mnt/run
        echo "$(_ "Setting up rEFInd...")"
        chroot /mnt pacman -S efibootmgr os-prober refind --noconfirm
        chroot /mnt refind-install
        echo "$(_ "rEFInd installed")"
    }

    boot=$(dialog --title "$(_ "UEFI Bootloader Selection")"  --ok-label "$(_ "Select")" --no-cancel \
    --menu "$(_ "Choose bootloader:")" 15 40 4 \
    1 "$(_ "GRUB")" \
    2 "$(_ "EFISTUB")" \
    3 "$(_ "rEFInd")" 3>&1 1>&2 2>&3)

    case $boot in
        1) grub ;;
        2) efistub ;;
        3) refind ;;
    esac
else
    function grub() {
        BOOT_PART=$(findmnt -n -o SOURCE /mnt/boot 2>/dev/null || findmnt -n -o SOURCE /mnt)
        BOOT_NUMBER=$(echo "$BOOT_PART" | sed 's/.*[^0-9]\([0-9]\+\)$/\1/')
        echo "$(_ "Setting up GRUB for BIOS...")"
        fast-chroot /mnt pacman -S grub os-prober --noconfirm
        fast-chroot /mnt grub-install --target=i386-pc --boot-directory=/boot --recheck "${DISK}"
        fast-chroot /mnt bash -c 'sed -i "s/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR=\"$GRUB_DISTRIBUTOR_NAME_BIOS\"/" /etc/default/grub || echo "GRUB_DISTRIBUTOR=\"$GRUB_DISTRIBUTOR_NAME_BIOS\"" >> /etc/default/grub'
        fast-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
        echo "$(_ "GRUB installed for BIOS")"
    }

    function syslinux() {
        KERNEL=""
        INITRAMFS=""
        if chroot /mnt test -f /boot/vmlinuz-linux; then
            KERNEL="linux"
        elif chroot /mnt test -f /boot/vmlinuz-linux-zen; then
            KERNEL="linux-zen"
        elif chroot /mnt test -f /boot/vmlinuz-linux-lts; then
            KERNEL="linux-lts"
        else
            echo "$(_ "Error: kernel not found")"
            exit 1
        fi
        echo "$(_ "Setting up Syslinux...")"
        BOOT_PART=$(findmnt -n -o SOURCE /mnt/boot 2>/dev/null || findmnt -n -o SOURCE /mnt)
        BOOT_NUMBER=$(echo "$BOOT_PART" | sed 's/.*[^0-9]\([0-9]\+\)$/\1/')
        parted "$DISK" set "$BOOT_NUMBER" boot on

        chroot /mnt pacman -S syslinux --noconfirm
        mkdir -p /mnt/boot/syslinux
        chroot /mnt extlinux --install /boot/syslinux
        cp /mnt/usr/lib/syslinux/bios/*.c32 /mnt/boot/syslinux/
        dd if=/mnt/usr/lib/syslinux/bios/mbr.bin of="$DISK" bs=440 count=1 conv=notrunc

        cat > /mnt/boot/syslinux/syslinux.cfg << EOFD
DEFAULT Quasarlinux
PROMPT 0
TIMEOUT 50

LABEL Quasarlinux
    KERNEL /vmlinuz-$KERNEL
    APPEND root=UUID=$ROOT_UUID rw
    INITRD /initramfs-$KERNEL.img
EOFD

        # Заменяем UUID в конфигурационном файле
        sed -i "s/\$ROOT_UUID/$ROOT_UUID/g" /mnt/boot/syslinux/syslinux.cfg
        echo "$(_ "Syslinux installed")"
    }

    boot=$(dialog --title "$(_ "BIOS Bootloader Selection")" --ok-label "$(_ "Select")"  --no-cancel --menu "$(_ "Choose bootloader:")" 15 40 4 \
    1 "$(_ "GRUB")" \
    2 "$(_ "Syslinux")" 3>&1 1>&2 2>&3)

    case $boot in
        1) grub ;;
        2) syslinux ;;
    esac
fi

echo "$(_ "Bootloader installation complete!")"
