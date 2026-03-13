#!/usr/bin/env bash
set -euo pipefail

# --- Инициализация локализации ---
SYSTEM_LANG=${LANG:0:5}
SUPPORTED_LANGS=("de_DE" "en_US" "es_ES" "fr_FR" "it_IT" "ja_JP" "pt_BR" "ru_RU" "tr_TR" "zh_CN")

LANG_FOUND=0
for lang in "${SUPPORTED_LANGS[@]}"; do
    if [ "$SYSTEM_LANG" = "$lang" ]; then
        LANG_FOUND=1
        break
    fi
done

if [ $LANG_FOUND -eq 0 ]; then
    export LANG="en_US.UTF-8"
else
    export LANG="$SYSTEM_LANG.UTF-8"
fi

export TEXTDOMAIN="installer"
export TEXTDOMAINDIR="/usr/local/sdk/global/locale"

if ! command -v gettext &> /dev/null; then
    _() { echo "$1"; }
    _err() { echo "ERROR: $1"; }
else
    _() { gettext -s "$1"; }
    _err() { echo "ERROR: $(gettext -s "$1")"; }
fi
# --------------------------------

mountChrootDirs() {
    local dirs=("/dev" "/dev/pts" "/proc" "/sys" "/run")
    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"
        mkdir -p "$targetDir"
        case "$dir" in
            "/dev") mount --bind "/dev" "$targetDir" ;;
            "/dev/pts") mount --bind "/dev/pts" "$targetDir" ;;
            "/proc") mount -t proc proc "$targetDir" ;;
            "/sys") mount -t sysfs sysfs "$targetDir" ;;
            "/run") mount -t tmpfs tmpfs "$targetDir" ;;
        esac

        if [ $? -ne 0 ]; then
            _err "Failed to mount $dir" >&2
            return 1
        fi
    done
    echo " * $(_ "File systems mounted for chroot")"
    return 0
}

unmountChrootDirs() {
    local dirs=("/run" "/sys" "/proc" "/dev/pts" "/dev")
    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"
        umount -R "$targetDir" 2>/dev/null || true
    done
    echo " * $(_ "File systems unmounted")"
}

runChroot() {
    chroot /mnt "$@"
}

addToSudoers() {
    local username="$1"
    local sudoersFile="/etc/sudoers.d/$username"
    local sudoersContent="$username ALL=(ALL:ALL) ALL"

    if ! echo "$sudoersContent" | runChroot tee "$sudoersFile" >/dev/null; then
        _err "Failed to configure sudoers" >&2
        return 1
    fi

    if ! runChroot chmod 440 "$sudoersFile"; then
        _err "Failed to set permissions on sudoers file" >&2
        return 1
    fi
    return 0
}

createUser() {
    local user_title=$(_ "User Setup")
    local enter_user_msg=$(_ "Enter username:")

    username=$(dialog --title "$user_title" --inputbox "$enter_user_msg" 10 50 3>&1 1>&2 2>&3 3>&-)

    if [ -z "$username" ]; then
        dialog --msgbox "$(_ "Username cannot be empty!")" 7 40
        return 1
    fi

    runChroot groupadd "$username" 2>/dev/null || true

    if ! runChroot useradd -m -g "$username" -G wheel "$username"; then
        _err "Failed to create user" >&2
        return 1
    fi

    while true; do
        password=$(dialog --title "$user_title" --insecure --passwordbox "$(_ "Enter password for") $username" 10 50 3>&1 1>&2 2>&3 3>&-)
        confirm=$(dialog --title "$user_title" --insecure --passwordbox "$(_ "Confirm password:")" 10 50 3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "$(_ "Password cannot be empty!")" 7 40
            continue
        fi
        [ "$password" = "$confirm" ] && break
        dialog --msgbox "$(_ "Passwords do not match!")" 7 50
    done

    echo "$username:$password" | runChroot chpasswd
    addToSudoers "$username"
    echo "$username"
}

setRootPassword() {
    local user_title=$(_ "Root Password Setup")
    while true; do
        password=$(dialog --title "$user_title" --insecure --passwordbox "$(_ "Enter root password:")" 10 50 3>&1 1>&2 2>&3 3>&-)
        confirm=$(dialog --title "$user_title" --insecure --passwordbox "$(_ "Confirm root password:")" 10 50 3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "$(_ "Password cannot be empty!")" 7 40
            continue
        fi
        [ "$password" = "$confirm" ] && break
        dialog --msgbox "$(_ "Passwords do not match!")" 7 50
    done

    echo "root:$password" | runChroot chpasswd
}

main() {
    clear
    mountChrootDirs
    trap unmountChrootDirs EXIT

    # Enable wheel
    runChroot sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers || true

    created_user=$(createUser)
    [ $? -ne 0 ] && exit 1

    setRootPassword

    dialog --title "$(_ "Done")" \
           --msgbox "$(_ "User created successfully:") $created_user\n$(_ "Root password set.")" 10 50
}

main
