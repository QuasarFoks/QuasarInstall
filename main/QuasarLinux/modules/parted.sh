#!/bin/bash
set -euo pipefail

# --- gettext init ---
SYSTEM_LANG=${LANG:0:5}
SUPPORTED_LANGS=("de_DE" "en_US" "es_ES" "fr_FR" "it_IT" "ja_JP" "pt_BR" "ru_RU" "tr_TR" "zh_CN")
LANG_FOUND=0
for lang in "${SUPPORTED_LANGS[@]}"; do
    [ "$SYSTEM_LANG" = "$lang" ] && LANG_FOUND=1 && break
done
if [ $LANG_FOUND -eq 0 ]; then
    export LANG="en_US.UTF-8"
else
    export LANG="$SYSTEM_LANG.UTF-8"
fi

export TEXTDOMAIN="installer"
export TEXTDOMAINDIR="/usr/local/sdk/locale"

if ! command -v gettext &> /dev/null; then
    _() { printf '%s' "$1"; }  # Без \n
else
    _() { gettext -s "$1"; }
fi
# --- end gettext init ---
HOME_PART_ADD=0
UEFI_MODE=0
export LUKS_MODE=0
[ -d /sys/firmware/efi ] && UEFI_MODE=1


WARNING() {
    dialog --clear \
        --title "ПРЕДУПРЕЖДЕНИЕ" \
        --backtitle "ОПАСНАЯ ОПЕРАЦИЯ" \
        --yes-label "Продолжить" \
        --no-label "Отмена" \
        --yesno "\n
Дальнейшие операции могут стереть данные с диска (-ов)!

Сохранение и перенос данных в разработке.
Данные boot/esp/root будут удалены.

Вы уверены, что хотите продолжить?" \
        12 60 \
        >/dev/tty 2>&1 || exit 0
}
WARNING_partition() {
    dialog --clear \
        --title "ПРЕДУПРЕЖДЕНИЕ" \
        --backtitle "ОПАСНАЯ ОПЕРАЦИЯ" \
        --yes-label "Продолжить" \
        --no-label "Отмена" \
        --yesno "\n
Дальнейшие операции могут стереть данные с раздела!

Вы уверены, что хотите продолжить?" \
        12 60 \
        >/dev/tty 2>&1 || exit 0
}
marking_disks() {
    WARNING
    clear
    local DISK_OPT
    DISK_OPT=$(dialog --title "$(_ "Select a marking type: ")" \
    --ok-label "$(_ "Select")" \
    --no-cancel \
    --menu "$(_ "Choose disks:")" \
    15 40 4 \
    1 "$(_ "single disk")" \
    2 "$(_ "multiple disks (beta)")" \
    3>&1 1>&2 2>&3)

    case $DISK_OPT in
        1)  _ "Select disk:"
            lsblk -d -o NAME,SIZE,MODEL,TYPE
            read -r -p "$(_ "Enter disk name (e.g. sda): ")" DISK
            export DISK="/dev/$DISK"
            if [ ! -e "$DISK" ]; then
                printf '%s\n' "$(_ "Error: disk %s not found")" "$DISK"
                exit 1
            fi
            WARNING
            SingleDisk
            ;;
        2)  _ "Select disks separated by a space:"
            lsblk -d -o NAME,SIZE,MODEL,TYPE
            read  -r -p "$(_ "Enter disk name (e.g. sda vda): ")" -a DISKS

            echo "DISKS: ${DISKS[*]}"

            # Проверка существования дисков
            for chdisk in "${DISKS[@]}"; do
                if [ ! -e "/dev/${chdisk}" ]; then
                    printf '%s\n' "$(_ "Error: disk /dev/%s not found")" "$chdisk"
                    exit 1
                fi
            done

            # Запуск cfdisk
            for disk in "${DISKS[@]}"; do
                cfdisk "/dev/${disk}"
            done
            ;;
    esac

    # Проверка только для варианта 2
    if [ "$DISK_OPT" = "2" ] && [ ${#DISKS[@]} -eq 0 ]; then
        echo "No disks provided!"
        return 1
    fi

    # Вывод информации о дисках (только для варианта 2)
    if [ "$DISK_OPT" = "2" ]; then
        for disk_shoh in "${DISKS[@]}"; do
            lsblk "/dev/${disk_shoh}"
        done
    fi
    read -r -p "$(_ "Enter root partition: ")" ROOT_PART
    ROOT_PART="/dev/$ROOT_PART"
    [ ! -e "$ROOT_PART" ] && printf '%s\n' "$(_ "Error: partition %s not found")" "$ROOT_PART" && exit 1
    fs=$(dialog --title "$(_ "Select filesystem")" --menu "$(_ "Choose filesystem:")" 15 70 5 \
        1 "$(_ "ext4")" \
        2 "$(_ "btrfs")" \
        3 "$(_ "xfs")" 3>&1 1>&2 2>&3 3>&-) || {
            _ "Skipping..."
            exit 0
        }

    case $fs in
        1) format "ext" ;;
        2) format "btrfs" ;;
        3) format "xfs" ;;
    esac
    if [ "$DISK_OPT" = "2" ]; then
        for disk_shoh in "${DISKS[@]}"; do
            lsblk "/dev/${disk_shoh}"
        done
    fi
    if [ $UEFI_MODE -eq 1 ]; then
        read -r -p "$(_ "Enter EFI partition: ")" BOOT_PART
        _ "Formatting EFI partition..."
        export  BOOT_PART="/dev/$BOOT_PART"
        [ ! -e "$BOOT_PART" ] && printf '%s\n' "$(_ "Error: partition %s not found")" "$BOOT_PART" && exit 1
        mkfs.fat -F32 "$BOOT_PART"

    else
        read -r -p "$(_ "Enter boot partition: ")" BOOT_PART
        _ "Formatting boot partition..."
        BOOT_PART="/dev/$BOOT_PART"
        [ ! -e "$BOOT_PART" ] && printf '%s\n' "$(_ "Error: partition %s not found")" "$BOOT_PART" && exit 1
        mkfs.ext2 -F "$BOOT_PART"
    fi
    mount_partitions
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  Additional sections                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    #[ ! -e "$BOOT_PART" ] && printf "$(_ "Error: partition %s not found")\n" "$BOOT_PART" && exit 1
	
    local MULT_PART=()
    local MULT_MOUNT=()

    # Показываем разделы
    for disk in "${DISKS[@]}"; do
        echo "--- /dev/${disk} ---"
        lsblk "/dev/${disk}"
    done

    # Выбираем разделы
    while true; do
        read -r -p "Enter partitions (space separated): " -a MULT_PART
        [ ${#MULT_PART[@]} -eq 0 ] && echo "No partitions!" && continue

        local valid=true
        for part in "${MULT_PART[@]}"; do
            [ ! -e "/dev/${part}" ] && echo "Error: /dev/${part} not found!" && valid=false
        done
        [ "$valid" = true ] && break

    done


    # Точки монтирования
    for part in "${MULT_PART[@]}"; do
        read  -r -p "Mount point for /dev/${part}: " mount
        MULT_MOUNT+=("${mount:-skip}")
    done

    # Монтируем
    echo ""
    for i in "${!MULT_PART[@]}"; do
        [ "${MULT_MOUNT[$i]}" = "skip" ] && continue
        echo "Mounting /dev/${MULT_PART[$i]} -> /mnt${MULT_MOUNT[$i]}"
        mkdir -p "/mnt${MULT_MOUNT[$i]}"

        fs=$(dialog --title "$(_ "Select filesystem")" --menu "$(_ "Choose filesystem:")" 15 70 5 \
            1 "$(_ "ext4")" \
            2 "$(_ "btrfs")" \
            3 "$(_ "xfs")" 3>&1 1>&2 2>&3 3>&-) || {
                _ "Skipping..."
                exit 0
            }

        case $fs in
            1) formathm "ext"  "/dev/${MULT_PART[$i]}" ;;
            2) formathm "btrfs" "/dev/${MULT_PART[$i]}" ;;
            3) formathm "xfs" "/dev/${MULT_PART[$i]}" ;;
        esac

        mount "/dev/${MULT_PART[$i]}" "/mnt${MULT_MOUNT[$i]}"
        unset fs
    done

    echo "Done!"
    df -h | grep -E "/dev/${MULT_PART[*]}"
}

old_os_backap() {
    fdisk -l "$DISK" | grep "^/dev"
    read -r -p "$(_ "Enter root partition: ")" ROOT_PART
    local ROOT_PART="/dev/$ROOT_PART"
    mount "$ROOT_PART" /mnt

    if [ $UEFI_MODE -eq 1 ]; then
        read -r -p "$(_ "Enter EFI partition: ")" BOOT_PART
        _ "Formatting EFI partition..."
        local BOOT_PART="/dev/$BOOT_PART"
        mount "$BOOT_PART" /mnt/boot/efi
    else
        read -r -p "$(_ "Enter boot partition: ")" BOOT_PART
        _ "Formatting boot partition..."
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
        local user
        user=$(basename "$old_user")

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
    --exclude=/mnt/mnt \
    --exclude=/mnt/media  \
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
        1) tar "$EXCLUDE" -c /mnt | xz -9 > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.xz" ;;
        2) tar "$EXCLUDE" -c /mnt | zstd -19 -T0 > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.zst" ;;
        3) tar "$EXCLUDE" -c /mnt | pigz -c > "/mnt/old.os/${OLD_OS_NAME}_backup.tar.gz" ;;
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
    WARNING
    _ "Auto-partitioning..."

    # Получаем размер диска в GB
    DISK_SIZE=$(fdisk -l "$DISK" | grep "Disk $DISK" | awk '{print int($3)}')
    printf '%s\n' "$(_ "Disk size: %s GB")" "$DISK_SIZE"

    # Проверяем, достаточно ли места
    if [ "$DISK_SIZE" -lt 10 ]; then
        _ "Disk is too small (minimum 10 GB required)"
        exit 1
    fi

    # Очищаем таблицу разделов
    _ "Cleaning partition table..."
    sgdisk -Z "$DISK" 2>/dev/null || dd if=/dev/zero of="$DISK" bs=1M count=100

    # Создаем новую таблицу разделов
    if [ $UEFI_MODE -eq 1 ]; then
        _ "Creating GPT..."
        parted -s "$DISK" mklabel gpt
    else
        _ "Creating MBR..."
        parted -s "$DISK" mklabel msdos
    fi

    # Создаем разделы
    _ "Creating partitions..."

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

    _ "Created partitions:"
    fdisk -l "$DISK" | grep "^/dev"
    echo "========================="
}
# Функция форматирования разделов
AUTO_format_partitions() {
    _ "Formatting partitions..."

    # Форматируем EFI/Boot раздел
    if [ $UEFI_MODE -eq 1 ]; then
        _ "Formatting EFI partition..."
        mkfs.fat -F32 "$BOOT_PART"
    else
        _ "Formatting boot partition..."
        mkfs.ext2 -F "$BOOT_PART"
    fi

    # Форматируем корневой раздел (ext4)
    _ "Formatting root partition..."
    mkfs.ext4 -F  "$ROOT_PART"

    #btrfs subvolume create /mnt/@root
    #btrfs subvolume create /mnt/@home
    #btrfs subvolume create /mnt/@var
    #btrfs subvolume create /mnt/@timeshift
    # Форматируем recovery раздел (ext2)
    # _ ""Formatting recovery partition...""
    # mkfs.ext2 -F "$RECOVERY_PART"

    # Создаем swap
    _ "Creating swap..."
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"

    _ "Formatting complete!"
}

# Функция монтирования разделов
mount_partitions() {
    _ "Mounting partitions..."

    # Монтируем корневой раздел
    mount "$ROOT_PART" /mnt
    #mkdir -p /mnt/home
    #mount -o subvol=@home "$ROOT_PART" /mnt/home
    #mkdir -p /mnt/.timeshift
    #mount -o subvol=@timeshift "$ROOT_PART" /mnt/.timeshift

    # Создаем и монтируем boot/efi
    if [ $UEFI_MODE -eq 1 ]; then
        mkdir -p /mnt/boot/efi
        mount "$BOOT_PART" /mnt/boot/efi
    else
        mkdir -p /mnt/boot
        mount "$BOOT_PART" /mnt/boot
    fi
    if [ $HOME_PART_ADD -eq 1 ]; then
        mkdir -p /mnt/home
        mount "$HOME_PART" /mnt/home
    else
        true
    fi
    # Создаем и монтируем recovery
    #mkdir -p /mnt/recovery
    #mount "$RECOVERY_PART" /mnt/recovery

    _ "Mounting complete!"
}
luks_enable_root() {
    _ "LUKS encryption setup"
    cryptsetup luksFormat --type luks2 --verify-passphrase "$ROOT_PART"

    # 2. Передаем пароль в cryptsetup
    cryptsetup luksOpen "$ROOT_PART" "QuasarRoot"
    export LUKS_MODE=1
}

format() {
    WARNING_partition
    case "$1" in
        ext)    if [ $LUKS_MODE -eq 1 ]; then
                    mkfs.ext4 "/dev/mapper/QuasarRoot"
                else
                    mkfs.ext4 -F "$ROOT_PART"
                fi
            ;;

        btrfs)  if [ $LUKS_MODE -eq 1 ]; then
                    mkfs.btrfs -f "/dev/mapper/QuasarRoot"
                else
                    mkfs.btrfs -f "$ROOT_PART"
                fi
            ;;

        xfs)    if [ $LUKS_MODE -eq 1 ]; then
                    mkfs.xfs -f "/dev/mapper/QuasarRoot"
                else
                    mkfs.xfs -f  "$ROOT_PART"
                fi
            ;;
    esac
}
formathm() {
    local PART="$2"
    case "$1" in
        ext) mkfs.ext4 -F "$PART"
            ;;

        btrfs) mkfs.btrfs -f "$HOME_PART"
            ;;

        xfs) mkfs.xfs -f  "$HOME_PART"
            ;;
    esac
}
SingleDisk() {
    # Основное меню выбора режима разметки
    _ "Select partitioning mode:"
    MODE=$(dialog --title "$(_ "Select mode")" --menu "$(_ "Choose partitioning mode:")" 15 60 3 \
        1 "$(_ "Auto")" \
        2 "$(_ "Manual")" \
        3 "$(_ "Replace OS") beta" \
        4 "$(_ "Exit")" 3>&1 1>&2 2>&3 3>&-)

    clear

    case $MODE in
        1)
            _ "Auto mode selected"
            auto_partition
            AUTO_format_partitions
            mount_partitions
            ;;
        2)
            _ "Manual mode selected"
            WARNING
            # Оригинальный код для ручной разметки
            cfdisk "$DISK"

            read -r -p "$(_ "Enter root partition: ")" ROOT_PART
            ROOT_PART="/dev/$ROOT_PART"
            [ ! -e "$ROOT_PART" ] && printf '%s\n' "$(_ "Error: partition %s not found")" "$ROOT_PART" && exit 1



            luks=$(dialog --title "$(_ "Encrypt root partition?")" --menu "$(_ "Enable LUKS encryption for root partition?")" 15 70 5 \
            1 "$(_ "Yes")" \
            2 "$(_ "No")" 3>&1 1>&2 2>&3 3>&-)

            case $luks in
                    1) luks_enable_root ;;
                    2) true ;;
            esac



            fs=$(dialog --title "$(_ "Select filesystem")" --menu "$(_ "Choose filesystem:")" 15 70 5 \
                1 "$(_ "ext4")" \
                2 "$(_ "btrfs")" \
                3 "$(_ "xfs")" 3>&1 1>&2 2>&3 3>&-) || {
                    _ "Skipping..."
                    exit 0
                }

            case $fs in
                1) format "ext" ;;
                2) format "btrfs" ;;
                3) format "xfs" ;;
            esac
            unset fs
            clear
            if [ $LUKS_MODE -eq 1 ]; then
                mount /dev/mapper/QuasarRoot /mnt
            else
                mount "$ROOT_PART" /mnt
            fi



            lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT "$DISK"
            if [ $UEFI_MODE -eq 1 ]; then
                read -r -p "$(_ "Enter EFI partition: ")" BOOT_PART
                _ "Formatting EFI partition..."
                export  BOOT_PART="/dev/$BOOT_PART"
                mkdir -p /mnt/boot/efi
                mkfs.fat -F32 "$BOOT_PART"
                mount "$BOOT_PART" /mnt/boot/efi
            else
                read -r -p "$(_ "Enter boot partition: ")" BOOT_PART
                _ "Formatting boot partition..."
                BOOT_PART="/dev/$BOOT_PART"
                mkdir -p /mnt/boot
                mkfs.ext2 -F "$BOOT_PART"
                mount "$BOOT_PART" /mnt/boot
            fi

            [ ! -e "$BOOT_PART" ] && printf '%s\n' "$(_ "Error: partition %s not found")" "$BOOT_PART" && exit 1

            read -r -p "$(_ "Create swap partition? [y/N]: ")" CREATE_SWAP
            if [[ $CREATE_SWAP =~ ^[Yy]$ ]]; then
                read -r -p "$(_ "Enter swap partition: ")" SWAP_PART
                SWAP_PART="/dev/$SWAP_PART"
                mkswap "$SWAP_PART"
                swapon "$SWAP_PART"
            fi

            _ "Final layout:"
            lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT "$DISK"
            _ "Partitioning complete!"
            ;;
        3) old_os_backap ;;

        4)
            _ "Exiting..."
            exit 0
            ;;
        *)
            _ "Unknown choice"
            exit 1
            ;;
    esac
}

main() {
    marking_disks
}
clear
main
_ "Final layout:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
echo "========================="
echo ""
_ "Partitioning complete!"
