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
export LUKS_MODE=0
[ -d /sys/firmware/efi ] && UEFI_MODE=1
clear
echo "$(_ "Select disk:")"
lsblk -d -o NAME,SIZE,MODEL,TYPE

read -p "$(_ "Enter disk name (e.g. sda): ")" DISK
export DISK="/dev/$DISK"
if [ ! -e "$DISK" ]; then
    printf "$(_ "Error: disk %s not found")\n" "$DISK"
    exit 1
fi

#   BEST_COMPRESS_SPEED
BLANCE="balance"
#   FAST_WEAKER_COMPRESSION
#

old_os_backap() {
    fdisk -l "$DISK" | grep "^/dev"
    read -p "$(_ "Enter root partition: ")" ROOT_PART
    local ROOT_PART="/dev/$ROOT_PART"
    mount "$ROOT_PART" /mnt

    if [ $UEFI_MODE -eq 1 ]; then
        read -p "$(_ "Enter EFI partition: ")" BOOT_PART
        echo "$(_ "Formatting EFI partition...")"
        local BOOT_PART="/dev/$BOOT_PART"
        mount "$BOOT_PART" /mnt/boot/efi
    else
        read -p "$(_ "Enter boot partition: ")" BOOT_PART
        echo "$(_ "Formatting boot partition...")"
        local BOOT_PART="/dev/$BOOT_PART"
        mount "$BOOT_PART" /mnt/boot
    fi

    local OLD_OS_NAME="OldOS"
    if [ -f /mnt/etc/os-release ]; then
        source /mnt/etc/os-release || source /mnt/usr/lib/os-release
        local OLD_OS_NAME="${NAME:-$ID}"
        local OLD_OS_NAME="${OLD_OS_NAME// /_}"
    fi
    mkdir -p /mnt/old.os/home_backup/

    for old_user in /mnt/home/*/; do
        [ -d "$old_user" ] || continue
        local user=$(basename "$old_user")

        # Сохраняем в /mnt/old.os/home_backup/username/
        local backup_path="/mnt/old.os/home_backup/$user"

        # Копируем с исключением опасных файлов
        rsync -av "$old_user" "$backup_path/"     \
        --exclude='.*cache*'    \
        --exclude='.*history'   \
        --exclude='.ssh'        \
        --exclude='.gnupg'       \
        --exclude='.local/share/keyrings'  \
        --exclude='.mozilla/firefox/*/logins.json'    \
        --exclude='*.iso'      \
        --exclude='*.img'         \
        --exclude='Downloads/'         \
        --exclude='.local/share/Trash/'

        echo "$(_ "Saved user ")$user $(_ " to ")$backup_path"


        rm -rf "$old_user"
    done


    rm -rf /mnt/home 2>/dev/null || true


    local EXCLUDE="--exclude=/mnt/*/.cache \
    --exclude=/mnt/var/cache \
    --exclude=/mnt/run  \
    --exclude=/mnt/tmp \
    --exclude=/mnt/var/run \
    --exclude=/mnt/var/lock  \
    --exclude=/mnt/swapfile \
    --exclude=/mnt/lost+found \
    --exclude=/mnt/.snapshots  \
    --exclude=/mnt/srv \
    --exclude=/mnt/mnt         --exclude=/mnt/media  \
    --exclude=/mnt/home \
    --exclude=/mnt/swap.img   \
    --exclude=/mnt/.Trash*   \
    --exclude=/mnt/*/backup*"

    # Создаём каталог для архива
    mkdir -p /mnt/old.os

    old_os_back=$(dialog --title "$(_ "Select mode")" --menu "$(_ "Choose compression mode:")" 15 60 3  \
        1 "tar.xz ($(_ "best compression"))"  \
        2 "tar.zst ($(_ "balanced"))"  \
        3 "tar.gz ($(_ "fast, weaker compression"))" 3>&1 1>&2 2>&3 3>&-)

    case "$old_os_back" in
        1) tar $EXCLUDE -c /mnt | xz -9 > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.xz" ;;
        2) tar $EXCLUDE -c /mnt | zstd -19 -T0 > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.zst" ;;
        3) tar $EXCLUDE -c /mnt | pigz -c > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.gz" ;;
    esac

    # 3. Удаляем всё кроме old.os и boot
    # 1. Сначала проверь, что найдётся:
    local TARGET="/mnt"

    # Проверка монтирования
    if ! mountpoint -q "$TARGET"; then
        echo "$(_ "Error: ")$TARGET $(_ "is not mounted. Exiting.")"
        exit 1
    fi

    # Проверка наличия нужных каталогов
    for dir in old.os boot; do
        if [[ ! -d "$TARGET/$dir" ]]; then
            echo "$(_ "Warning: ")$TARGET/$dir $(_ "does not exist!")"
        fi
    done

    # Удаляем всё, кроме old.os и boot
    find "$TARGET" -maxdepth 1 -mindepth 1 ! -name 'old.os' ! -name 'boot' -exec rm -rf {} +

}

# Функция авторазметки
auto_partition() {
    echo "$(_ "Auto-partitioning...")"

    # Получаем размер диска в GB
    DISK_SIZE=$(fdisk -l "$DISK" | grep "Disk $DISK" | awk '{print int($3)}')
    printf "$(_ "Disk size: %s GB")\n" "$DISK_SIZE"

    # Проверяем, достаточно ли места
    if [ "$DISK_SIZE" -lt 10 ]; then
        echo "$(_ "Disk is too small (minimum 10 GB required)")"
        exit 1
    fi

    # Очищаем таблицу разделов
    echo "$(_ "Cleaning partition table...")"
    sgdisk -Z "$DISK" 2>/dev/null || dd if=/dev/zero of="$DISK" bs=1M count=100

    # Создаем новую таблицу разделов
    if [ $UEFI_MODE -eq 1 ]; then
        echo "$(_ "Creating GPT...")"
        parted -s "$DISK" mklabel gpt
    else
        echo "$(_ "Creating MBR...")"
        parted -s "$DISK" mklabel msdos
    fi

    # Создаем разделы
    echo "$(_ "Creating partitions...")"

    if [ $UEFI_MODE -eq 1 ]; then
        # UEFI: ESP + swap + root
        parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
        parted -s "$DISK" set 1 esp on
        export BOOT_PART="${DISK}1"

        parted -s "$DISK" mkpart primary 513MiB 4.5GiB
        export SWAP_PART="${DISK}2"

        parted -s "$DISK" mkpart primary 4.5GiB 100%
        export ROOT_PART="${DISK}3"
    else
        # BIOS: boot + swap + root
        parted -s "$DISK" mkpart primary 1MiB 513MiB
        parted -s "$DISK" set 1 boot on
        export BOOT_PART="${DISK}1"

        parted -s "$DISK" mkpart primary 513MiB 4.5GiB
        export SWAP_PART="${DISK}2"

        parted -s "$DISK" mkpart primary 4.5GiB 100%
        export ROOT_PART="${DISK}3"
    fi

    partprobe "$DISK"
    sleep 2

    echo "$(_ "Created partitions:")"
    fdisk -l "$DISK" | grep "^/dev"
    echo "========================="
}
# Функция форматирования разделов
format_partitions() {
    echo "$(_ "Formatting partitions...")"

    # Форматируем EFI/Boot раздел
    if [ $UEFI_MODE -eq 1 ]; then
        echo "$(_ "Formatting EFI partition...")"
        mkfs.fat -F32 "$BOOT_PART"
    else
        echo "$(_ "Formatting boot partition...")"
        mkfs.ext2 -F "$BOOT_PART"
    fi

    # Форматируем корневой раздел (ext4)
    echo "$(_ "Formatting root partition...")"
    mkfs.ext4 -F "$ROOT_PART"

    # Форматируем recovery раздел (ext2)
    # echo "$(_ "Formatting recovery partition...")"
    # mkfs.ext2 -F "$RECOVERY_PART"

    # Создаем swap
    echo "$(_ "Creating swap...")"
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"

    echo "$(_ "Formatting complete!")"
}

# Функция монтирования разделов
mount_partitions() {
    echo "$(_ "Mounting partitions...")"

    # Монтируем корневой раздел
    mount "$ROOT_PART" /mnt

    # Создаем и монтируем boot/efi
    if [ $UEFI_MODE -eq 1 ]; then
        mkdir -p /mnt/boot/efi
        mount "$BOOT_PART" /mnt/boot/efi
    else
        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot
    fi

    # Создаем и монтируем recovery
    mkdir -p /mnt/recovery
    mount "$RECOVERY_PART" /mnt/recovery

    echo "$(_ "Mounting complete!")"
}

# Основное меню выбора режима разметки
echo "$(_ "Select partitioning mode:")"
MODE=$(dialog --title "$(_ "Select mode")" --menu "$(_ "Choose partitioning mode:")" 15 60 3 \
    1 "$(_ "Auto")" \
    2 "$(_ "Manual")" \
    3 "$(_ "Replace OS") beta" \
    4 "$(_ "Exit")" 3>&1 1>&2 2>&3 3>&-)

clear

case $MODE in
    1)
        echo "$(_ "Auto mode selected")"
        auto_partition
        format_partitions
        mount_partitions
        ;;
    2)
        echo "$(_ "Manual mode selected")"
        # Оригинальный код для ручной разметки
        cfdisk "$DISK"

        read -p "$(_ "Enter root partition: ")" ROOT_PART
        ROOT_PART="/dev/$ROOT_PART"
        [ ! -e "$ROOT_PART" ] && printf "$(_ "Error: partition %s not found")\n" "$ROOT_PART" && exit 1

        luks_enable_root() {
            echo "$(_ "LUKS encryption setup")"
            cryptsetup luksFormat --type luks2 --verify-passphrase "$ROOT_PART"

            # 2. Передаем пароль в cryptsetup
            cryptsetup luksOpen "$ROOT_PART" "QuasarRoot"
            export LUKS_MODE=1
        }

        luks=$(dialog --title "$(_ "Encrypt root partition?")" --menu "$(_ "Enable LUKS encryption for root partition?")" 15 70 5 \
        1 "$(_ "Yes")" \
        2 "$(_ "No")" 3>&1 1>&2 2>&3 3>&-)

        case $luks in
                1) luks_enable_root ;;
                2) true ;;
        esac

        format() {
            ext() {
                if [ $LUKS_MODE -eq 1 ]; then
                    mkfs.ext4 "/dev/mapper/QuasarRoot"
                else
                    mkfs.ext4 -F "$ROOT_PART"
                fi
            }

            btrfs() {
                if [ $LUKS_MODE -eq 1 ]; then
                     mkfs.btrfs -f "/dev/mapper/QuasarRoot"
                else
                     mkfs.btrfs -f "$ROOT_PART"
                fi
            }

            xfs() {
                if [ $LUKS_MODE -eq 1 ]; then
                    mkfs.xfs -f "/dev/mapper/QuasarRoot"
                else
                    mkfs.xfs -f  "$ROOT_PART"
                fi
            }

            fs=$(dialog --title "$(_ "Select filesystem")" --menu "$(_ "Choose filesystem:")" 15 70 5 \
            1 "$(_ "ext4")" \
            2 "$(_ "btrfs")" \
            3 "$(_ "xfs")" 3>&1 1>&2 2>&3 3>&-)

            if [ $? -ne 0 ]; then
                echo "$(_ "Skipping...")"
                exit 0
            fi

            case $fs in
                1) ext ;;
                2) btrfs ;;
                3) xfs ;;
            esac
            clear
            if [ $LUKS_MODE -eq 1 ]; then
                mount /dev/mapper/QuasarRoot /mnt
            else
                mount "$ROOT_PART" /mnt
            fi
        }
        format

        lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT $DISK
        if [ $UEFI_MODE -eq 1 ]; then
            read -p "$(_ "Enter EFI partition: ")" BOOT_PART
            echo "$(_ "Formatting EFI partition...")"
            export  BOOT_PART="/dev/$BOOT_PART"
            mkdir -p /mnt/boot/efi
            mkfs.fat -F32 "$BOOT_PART"
            mount "$BOOT_PART" /mnt/boot/efi
        else
            read -p "$(_ "Enter boot partition: ")" BOOT_PART
            echo "$(_ "Formatting boot partition...")"
            BOOT_PART="/dev/$BOOT_PART"
            mkdir -p /mnt/boot
            mkfs.ext2 -F "$BOOT_PART"
            mount "$BOOT_PART" /mnt/boot
        fi

        [ ! -e "$BOOT_PART" ] && printf "$(_ "Error: partition %s not found")\n" "$BOOT_PART" && exit 1

        # Дополнительные опции для ручного режима
        read -p "$(_ "Create recovery partition? [y/N]: ")" CREATE_RECOVERY
        if [[ $CREATE_RECOVERY =~ ^[Yy]$ ]]; then
            read -p "$(_ "Enter recovery partition: ")" RECOVERY_PART
            echo "$(_ "Formatting recovery partition...")"
            RECOVERY_PART="/dev/$RECOVERY_PART"
            mkfs.ext2 -F "$RECOVERY_PART"
            mkdir -p /mnt/recovery
            mount "$RECOVERY_PART" /mnt/recovery
        fi

        read -p "$(_ "Create swap partition? [y/N]: ")" CREATE_SWAP
        if [[ $CREATE_SWAP =~ ^[Yy]$ ]]; then
            read -p "$(_ "Enter swap partition: ")" SWAP_PART
            SWAP_PART="/dev/$SWAP_PART"
            mkswap "$SWAP_PART"
            swapon "$SWAP_PART"
        fi

        echo "$(_ "Final layout:")"
        lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT $DISK
        echo "$(_ "Partitioning complete!")"
        ;;
    3) old_os_backap ;;

    4)
        echo "$(_ "Exiting...")"
        exit 0
        ;;
    *)
        echo "$(_ "Unknown choice")"
        exit 1
        ;;
esac


echo "$(_ "Final layout:")"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT "$DISK"
echo "========================="
echo ""
echo "$(_ "Partitioning complete!")"
