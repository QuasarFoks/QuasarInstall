#!/bin/bash
set -euo pipefail

# Языковые переменные


# mountChrootDirs — монтирует необходимые файловые системы для chroot
mountChrootDirs() {
    local dirs=("/dev" "/dev/pts" "/proc" "/sys" "/run")

    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"

        # Создаем директорию если её нет
        mkdir -p "$targetDir"

        # Монтируем
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
            printf "${ERROR_MOUNT}\n" "$dir" >&2
            return 1
        fi
    done

    echo " * Файловые системы смонтированы для chroot"
    return 0
}

# unmountChrootDirs — отмонтирует файловые системы после работы
unmountChrootDirs() {
    local dirs=("/run" "/sys" "/proc" "/dev/pts" "/dev")

    for dir in "${dirs[@]}"; do
        targetDir="/mnt$dir"
        umount -R "$targetDir" 2>/dev/null || true
    done

    echo " * Файловые системы отмонтированы"
}

# runChroot — запускает команду внутри chroot
runChroot() {
    chroot /mnt "$@"
}

# addToSudoers — добавляет пользователя в sudoers
addToSudoers() {
    local username="$1"
    printf "${ADD_TO_SUDO}\n" "$username"

    # Создаем файл в /etc/sudoers.d/ (более безопасно)
    local sudoersFile="/etc/sudoers.d/$username"
    local sudoersContent="$username ALL=(ALL:ALL) ALL"

    # Записываем конфиг в chroot
    if ! echo "$sudoersContent" | runChroot tee "$sudoersFile" >/dev/null; then
        printf "${ERROR_SUDO}\n" >&2
        return 1
    fi

    # Устанавливаем правильные права (только root для чтения)
    if ! runChroot chmod 440 "$sudoersFile"; then
        printf "${ERROR_PERMISSIONS}\n" >&2
        return 1
    fi

    printf "${USER_ADDED_TO_SUDO}\n" "$username"
    return 0
}

# createUser — создаёт пользователя и группу через dialog
createUser() {
    # Диалог для ввода имени пользователя
    username=$(dialog --title "$USER_SETUP_TITLE" \
                      --inputbox "$ENTER_USERNAME" \
                      10 50 \
                      3>&1 1>&2 2>&3 3>&-)

    if [ -z "$username" ]; then
        dialog --msgbox "${USERNAME_EMPTY}" 7 40
        return 1
    fi

    if [ "$username" = "root" ]; then
        dialog --msgbox "${USERNAME_ROOT}" 7 40
        return 1
    fi

    # Создаем группу
    printf "${CREATE_GROUP}\n" "$username"
    runChroot groupadd "$username" 2>/dev/null || true

    # Создаем пользователя
    printf "${CREATE_USER}\n" "$username"
    if ! runChroot useradd -m -g "$username" -G wheel "$username"; then
        printf "${ERROR_CREATE_USER}\n" >&2
        return 1
    fi

    # Устанавливаем пароль через диалог
    while true; do
        password=$(dialog --title "$USER_SETUP_TITLE" \
                          --insecure \
                          --passwordbox "$(printf "${SET_PASSWORD}" "$username")" \
                          10 50 \
                          3>&1 1>&2 2>&3 3>&-)

        password_confirm=$(dialog --title "$USER_SETUP_TITLE" \
                                  --insecure \
                                  --passwordbox "Подтвердите пароль:" \
                                  10 50 \
                                  3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "Пароль не может быть пустым!" 7 40
            continue
        fi

        if [ "$password" != "$password_confirm" ]; then
            dialog --msgbox "Пароли не совпадают! Попробуйте снова." 7 50
            continue
        fi

        break
    done

    # Устанавливаем пароль
    echo "$username:$password" | runChroot chpasswd
    if [ $? -ne 0 ]; then
        printf "${ERROR_SET_PASSWORD}\n" >&2
        return 1
    fi

    # Добавляем в sudo
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
        password=$(dialog --title "$USER_SETUP_TITLE" \
                          --insecure \
                          --passwordbox "$SET_ROOT_PASSWORD" \
                          10 50 \
                          3>&1 1>&2 2>&3 3>&-)

        password_confirm=$(dialog --title "$USER_SETUP_TITLE" \
                                  --insecure \
                                  --passwordbox "Подтвердите пароль для root:" \
                                  10 50 \
                                  3>&1 1>&2 2>&3 3>&-)

        if [ -z "$password" ]; then
            dialog --msgbox "Пароль не может быть пустым!" 7 40
            continue
        fi

        if [ "$password" != "$password_confirm" ]; then
            dialog --msgbox "Пароли не совпадают! Попробуйте снова." 7 50
            continue
        fi

        break
    done

    # Устанавливаем пароль
    echo "root:$password" | runChroot chpasswd
    if [ $? -ne 0 ]; then
        printf "${ERROR_SET_PASSWORD}\n" >&2
        return 1
    fi

    return 0
}

# enableSudoGroup — включает группу wheel в sudo
enableSudoGroup() {
    echo "$ENABLE_SUDO_GROUP"

    # Раскомментируем строку с %wheel в sudoers
    if ! runChroot sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers; then
        printf "${WARNING_WHEEL}\n" >&2
        return 1
    fi

    return 0
}

main() {
    clear
    echo "====================================="
    echo "      $USER_SETUP_TITLE"
    echo "====================================="

    # Монтируем файловые системы для chroot
    if ! mountChrootDirs; then
        exit 1
    fi

    # Гарантируем отмонтирование при выходе
    trap unmountChrootDirs EXIT

    # Включаем группу wheel в sudo
    enableSudoGroup || true

    # Создаем пользователя
    username=$(createUser)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    echo ""

    # Устанавливаем пароль root
    if ! setRootPassword; then
        exit 1
    fi

    clear
    echo "\n====================================="
    printf "  ${USER_CREATED_SUCCESS}\n" "$username"
    echo "====================================="

    # Показываем итоговое сообщение
    dialog --title "Готово" \
           --msgbox "$(printf "${USER_CREATED_SUCCESS}\n\nПользователь: $username\nПароль root установлен" "$username")" \
           10 50
}

main
