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

base_system() {
    echo "$(_ "Installing base system...")"
    basestrap /mnt terminus-font iptables-nft base base-devel mkinitcpio openrc dbus dbus-openrc elogind-openrc linux-firmware dialog \
        acpid flatpak acpid-openrc chrony-openrc dash chrony linux-api-headers \
        rsync lib32-udev networkmanager networkmanager-openrc
    fast-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

linux_zen_base() {
    base_system
    basestrap /mnt linux-zen linux-zen-headers
}
linux_lts_base() {
    base_system
    basestrap /mnt linux-lts linux-lts-headers
}
linux_base() {
    base_system
    basestrap /mnt linux linux-headers
}


base_system_kernel=$(dialog --title "$(_ "Select kernel")" --menu "$(_ "Kernel")" 12 50 5     1 "$(_ "Zen kernel (optimized for desktop)")"     2 "$(_ "LTS kernel (long-term support)")"     3 "$(_ "Vanilla kernel")"     3>&1 1>&2 2>&3 3>&-)

case $? in
    0)
        case $base_system_kernel in
            1) linux_zen_base ;;
            2) linux_lts_base ;;
            3) linux_base ;;
            *)
                echo "$(_ "Error")$(_ "Unknown choice")"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "$(_ "Operation cancelled")"
        exit 1
        ;;
esac
unset base_system_kernel

################################################################################
# Создание файлов OS release
config_system() {
    cat > /mnt/usr/lib/os-release << 'OS_EOF'
NAME="Quasar Linux REV-1.3"
PRETTY_NAME="Quasar Linux"
ID=quasar
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://quasarfoks.github.io/QuasarLinux"
DOCUMENTATION_URL="https://github.com/b-e-n-z1342/QuasarLinux/wiki"
BUG_REPORT_URL="https://github.com/QuasarFoks/QuasarLinux/issues"
PRIVACY_POLICY_URL="https://quasarfoks.github.io/policy"
LOGO=quasarlogo
OS_EOF

    cat > /mnt/etc/lsb-release << 'LSB_EOF'
DISTRIB_ID=Quasar
DISTRIB_RELEASE=1.3
DISTRIB_DESCRIPTION="Quasar Linux"
DISTRIB_CODENAME=rolling
LSB_EOF

    cat > /mnt/etc/rc.conf << 'EOF'
# =============================================
# OpenRC Configuration - Parallel Boot Optimized
# =============================================

# ПАРАЛЛЕЛЬНАЯ ЗАГРУЗКА
rc_parallel="YES"           # Включить параллельный запуск
rc_parallel_rcwait="NO"    # Не ждать завершения rc-сервисов


# ЛОГИРОВАНИЕ И ОТЛАДКА
rc_logger="YES"            # Логировать в /var/log/rc.log
rc_log_path="/var/log/rc.log"
rc_verbose="NO"            # Тихий режим (меньше вывода)

# СИСТЕМНЫЕ НАСТРОЙКИ
unicode="YES"              # Поддержка Unicode
rc_cgroup_mode="unified"   # Режим cgroups

# ТАЙМАУТЫ
rc_timeout_stopsec="10"    # Таймаут остановки (секунд)
rc_timeout_startsec="20"   # Таймаут запуска

# СЕТЬ
rc_nocolor="NO"            # Цветной вывод
rc_hotplug="*"             # Обработка hotplug событий
EOF

    # 2. Дополнительные настройки для ускорения
    cat > /mnt/etc/conf.d/rc << 'EOF'
# Дополнительные настройки для ускорения загрузки
RC_PARALLEL_STARTUP="yes"        # Параллельный запуск
RC_PARALLEL_STARTUP_NICE="10"    # Приоритет для параллельных задач
RC_RETRY_KILL="3"               # Попыток убить процесс
RC_RETRY_TIMEOUT="5"            # Пауза между попытками
EOF
}

config_system
###############################################################################
# Принудительная настройка issue
echo "Quasar Linux \r \l" > /mnt/etc/issue
echo "Quasar Linux" > /mnt/etc/issue.net
echo "$(_ "Welcome to Quasar Linux!")" > /mnt/etc/motd
cd /mnt/bin
ln -sf dash sh
cd

sleep 5
clear

mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /run /mnt/run

echo "$(_ "Configuring locale...")" >> /mnt/etc/locale.conf || echo "en_US.UTF-8" >> /mnt/etc/locale.conf
chroot /mnt locale-gen


echo "$(_ "Activating services")"


rm /mnt/etc/fstab
fstabgen -U /mnt >> /mnt/etc/fstab

# Активация сервисов
#   {service}       {runlevel}
#
#   1) UDEV         sysvinit
#   2) DBUS         boot
#   3) ELOGIND      boot
#   4) ACPID        default
#
######################################################################################
#  udev

echo "$(_ "Configuring services...")"

if chroot /mnt rc-update add udev sysinit; then
    echo "udev$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")udev..."
    chroot /mnt pacman -S udev lib32-udev || chroot /mnt pacman -S udev
    chroot /mnt rc-update add udev sysinit
fi

######################################################################################
# dbus

if chroot /mnt rc-update add dbus boot; then
    echo "dbus$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")dbus..."
    chroot /mnt pacman -S dbus dbus-openrc
    chroot /mnt rc-update add dbus boot
fi

######################################################################################
# elogind

if chroot /mnt rc-update add elogind boot; then
    echo "elogind$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")elogind..."
    chroot /mnt pacman -S elogind elogind-openrc
    chroot /mnt rc-update add elogind boot
fi

########################################################################################
# acpid

if chroot /mnt rc-update add acpid default; then
    echo "acpid$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")acpid..."
    chroot /mnt pacman -S acpid acpid-openrc
    chroot /mnt rc-update add acpid default
fi

#########################################################################################
# network manager

if chroot /mnt rc-update add NetworkManager default; then
    echo "network manager$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")network manager..."
    chroot /mnt pacman -S networkmanager networkmanager-openrc
    chroot /mnt rc-update add NetworkManager default
fi

#########################################################################################
# chrony

if chroot /mnt rc-update add chrony default; then
    echo "chrony${$(_ " added to autostart")}"
else
    echo "$(_ "Reinstalling ")chrony..."
    chroot /mnt pacman -S chrony-openrc
    chroot /mnt rc-update add chrony default
fi

#########################################################################################
# Копирование конфигурационных файлов

if [ -f /installer/profiles/base/pacman.conf ]; then
    rm /mnt/etc/pacman.conf
    cp /installer/profiles/base/pacman.conf /mnt/etc/
else
    echo "$(_ "Warning: ")pacman.conf $(_ "not found, using default")"
fi



#########################################################################################
# Копирование post-инсталляционных скриптов


#########################################################################################

# Убираем автогенерацию motd
if [ -d /mnt/etc/update-motd.d/ ]; then
    rm -rf /mnt/etc/update-motd.d/
fi

########################################################################################
# Симлинк для совместимости
ln -sf /usr/lib/os-release /mnt/etc/os-release 2>/dev/null || true

##########################################################################################

if [ -d /installer/profiles/base/pixmaps ]; then
    rm -rf /mnt/usr/share/pixmaps
    cp -r /installer/profiles/base/pixmaps /mnt/usr/share
else
    echo "$(_ "Warning: ")pixmaps $(_ "not found, using default")"
fi

###########################################################################################
# Распаковка recovery образа
echo "$(_ "Installing recovery...")"
# wget https://github.com/b-e-n-z1342/Recovery/releases/download/0.1/recovery-0.1.tar.xz -p /installer/image/recovery.tar.xz
# Проверяем существование recovery раздела
if mountpoint -q /mnt/recovery; then
    echo "$(_ "Recovery partition mounted")"

    # Проверяем существование recovery архива
    if [ -f "/installer/image/recovery.tar.xz" ]; then
        echo "$(_ "Found recovery archive")"

        # Распаковываем с сохранением прав и перезаписью существующих файлов
        tar -xJf "/installer/image/recovery.tar.xz" -C /mnt/recovery --strip-components=1 --keep-newer-files

        if [ $? -eq 0 ]; then
            echo "$(_ "Recovery installed successfully")"

            # Добавляем запись в fstab для автоматического монтирования recovery
            if ! grep -q "/recovery" /mnt/etc/fstab; then
                RECOVERY_UUID=$(blkid -s UUID -o value "$(mount | grep '/mnt/recovery' | cut -d' ' -f1)")
                if [ -n "$RECOVERY_UUID" ]; then
                    echo "# Recovery partition" >> /mnt/etc/fstab
                    echo "UUID=$RECOVERY_UUID /recovery ext2 defaults,noatime 0 2" >> /mnt/etc/fstab
                    echo "$(_ "Recovery added to fstab")"
                fi
            fi
        else
            echo "$(_ "Error: failed to unpack recovery")"
            exit 1
        fi
    else
        echo "$(_ "Warning: ")recovery.tar.xz $(_ "not found at ")/installer/image/recovery.tar.xz"
        echo ""
        echo "$(_ "Searching for recovery archive in alternative locations...")"

        # Поиск recovery архива в других возможных местах
        if [ -f "/installer/recovery.tar.xz" ]; then
            echo "$(_ "Found alternative recovery archive")"
            tar -xJf "/installer/recovery.tar.xz" -C /mnt/recovery --strip-components=1 --keep-newer-files

        elif [ -f "/recovery.tar.xz" ]; then
            echo "$(_ "Found /recovery.tar.xz, extracting...")"
            tar -xJf "/recovery.tar.xz" -C /mnt/recovery --strip-components=1 --keep-newer-files

        else
            echo "$(_ "Recovery archive not found, skipping")"
        fi
    fi
else
    echo "$(_ "Warning: recovery partition not mounted")"
fi
git clone https://github.com/QuasarFoks/Systemd-rc.git
SRC_FILE="Systemd-rc/src/systemctl/openrc/systemctl.go"
go build -o "systemctl" "$SRC_FILE"
cp systemctl /mnt/bin


clear
echo "$(_ "Installing branding")"

chmod +x /mnt/usr/local/bin/post_install
wget -O QuasarLinux.tar.bz2 "https://github.com/QuasarFoks/QuasarLinux/releases/download/REV-1.1-image/system-rev-1-1.tar.bz2" || {
    echo "$(_ "Error: download failed")"
    exit 1
}

downloaded_hash=$(sha256sum QuasarLinux.tar.bz2 | cut -d' ' -f1)
expected_hash="ad19f72b38d020e72bf47756e85787687cd35bf711836e973e848dff8c8a5c78"

if [ "$downloaded_hash" = "$expected_hash" ]; then
    echo "$(_ "Hash check passed")"
    tar -xf QuasarLinux.tar.bz2 -C /mnt/
    rm -f /mnt/README 2>/dev/null
else
    echo "$(_ "Hash check failed!")"
    echo "$(_ "Expected: ")$expected_hash"
    echo "$(_ "Got:      ")$downloaded_hash"
    exit 1
fi

echo "$(_ "Base installation completed!")"

unset expected_hash
unset downloaded_hash
