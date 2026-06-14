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

# mountChrootDirs — монтирует необходимые файловые системы для chroot
mountChrootDirs() {
    local dirs=("/dev" "/dev/pts" "/proc" "/sys" "/run")

    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"
        mkdir -p "$targetDir"
        case "$dir" in
            "/dev")
                mount --bind "/dev" "$targetDir"
                ;;
            "/dev/pts")
                mount --bind "/dev/pts" "$targetDir"
                ;;
            "/proc")
                mount -t proc proc "$targetDir"
                ;;
            "/sys")
                mount -t sysfs sysfs "$targetDir"
                ;;
            "/run")
                mount -t tmpfs tmpfs "$targetDir"
                ;;
        esac

        if [ $? -ne 0 ]; then
            printf "$(_ "Error mounting %s")\n" "$dir" >&2
            return 1
        fi
    done

    echo " * $(_ "Filesystems mounted for chroot")"
    return 0
}

# unmountChrootDirs — отмонтирует файловые системы после работы
unmountChrootDirs() {
    local dirs=("/run" "/sys" "/proc" "/dev/pts" "/dev")

    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"
        umount -R "$targetDir" 2>/dev/null || true
    done

    echo " * $(_ "Filesystems unmounted")"
}

# runChroot — запускает команду внутри chroot
runChroot() {
    chroot /mnt "$@"
}

# addToSudoers — добавляет пользователя в sudoers
addToSudoers() {
    local username="$1"
    printf "$(_ "Adding %s to sudoers")\n" "$username"

    local sudoersFile="/etc/sudoers.d/$username"
    local sudoersContent="$username ALL=(ALL:ALL) ALL"

    if ! echo "$sudoersContent" | runChroot tee "$sudoersFile" >/dev/null; then
        printf "$(_ "Error: failed to add sudoers entry")\n" >&2
        return 1
    fi

    if ! runChroot chmod 440 "$sudoersFile"; then
        printf "$(_ "Error: failed to set sudoers permissions")\n" >&2
        return 1
    fi

    printf "$(_ "User %s added to sudoers")\n" "$username"
    return 0
}

# createUser — создаёт пользователя и группу через dialog
createUser() {
    username=$(dialog --title "$(_ "User Setup")" \
    --inputbox "$(_ "Enter username:")" \
    10 50 \
    3>&1 1>&2 2>&3 3>&-)

    if [ -z "$username" ]; then
        dialog --msgbox "$(_ "Username cannot be empty!")" 7 40
        return 1
    fi

    if [ "$username" = "root" ]; then
        dialog --msgbox "$(_ "Username cannot be 'root'!")" 7 40
        return 1
    fi

    printf "$(_ "Creating group %s")\n" "$username"
    runChroot groupadd "$username" 2>/dev/null || true

    printf "$(_ "Creating user %s")\n" "$username"
    if ! runChroot useradd -m -g "$username" -G wheel "$username"; then
        printf "$(_ "Error: failed to create user")\n" >&2
        return 1
    fi

    while true; do
        password=$(dialog --title "$(_ "User Setup")"  \
        --insecure \
        --passwordbox "$(printf "$(_ "Set password for %s:")" "$username")" \
        10 50 3>&1 1>&2 2>&3 3>&-)

        password_confirm=$(dialog --title "$(_ "User Setup")" --insecure  --passwordbox "$(_ "Confirm password:")" 10 50  3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "$(_ "Password cannot be empty!")" 7 40
            continue
        fi

        if [ "$password" != "$password_confirm" ]; then
            dialog --msgbox "$(_ "Passwords do not match! Try again.")" 7 50
            continue
        fi

        break
    done

    echo "$username:$password" | runChroot chpasswd
    if [ $? -ne 0 ]; then
        printf "$(_ "Error: failed to set password")\n" >&2
        return 1
    fi

    if ! addToSudoers "$username"; then
        return 1
    fi
    export $username
    echo "$username"
    return 0
}

# setRootPassword — устанавливает пароль root через dialog
setRootPassword() {
    while true; do
        password=$(dialog --title "$(_ "User Setup")"  --insecure --passwordbox "$(_ "Set root password:")" 10 50 3>&1 1>&2 2>&3 3>&-)

        password_confirm=$(dialog --title "$(_ "User Setup")"  --insecure --passwordbox "$(_ "Confirm root password:")" 10 50  3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "$(_ "Password cannot be empty!")" 7 40
            continue
        fi

        if [ "$password" != "$password_confirm" ]; then
            dialog --msgbox "$(_ "Passwords do not match! Try again.")" 7 50
            continue
        fi

        break
    done

    echo "root:$password" | runChroot chpasswd
    if [ $? -ne 0 ]; then
        printf "$(_ "Error: failed to set password")\n" >&2
        return 1
    fi

    return 0
}

# enableSudoGroup — включает группу wheel в sudo
enableSudoGroup() {
    echo "$(_ "Enabling wheel group in sudoers")"

    if ! runChroot sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers; then
        printf "$(_ "Warning: failed to enable wheel group")\n" >&2
        return 1
    fi

    return 0
}

main() {
    clear
    echo "====================================="
    echo "      $(_ "User Setup")"
    echo "====================================="

    if ! mountChrootDirs; then
        exit 1
    fi

    trap unmountChrootDirs EXIT

    enableSudoGroup || true

    username=$(createUser)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    echo ""

    if ! setRootPassword; then
        exit 1
    fi

    clear
    echo "\n====================================="
    printf "  $(_ "User %s created successfully")\n" "$username"
    echo "====================================="

    dialog --title "$(_ "Done")"  --msgbox "$(printf "$(_ "User %s created successfully\n\nUser: %s\nRoot password set")" "$username" "$username")" 10 50
}

main
