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

base_system() {
    _ "Installing base system..."
    basestrap /mnt terminus-font iptables base base-devel \
        mkinitcpio openrc dbus dbus-openrc elogind-openrc linux-firmware dialog \
        acpid flatpak acpid-openrc chrony-openrc dash chrony linux-api-headers \
        rsync lib32-udev networkmanager networkmanager-openrc pacman-static
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


base_system_kernel=$(dialog --title "$(_ "Select kernel")" --menu "$(_ "Kernel")" 12 50 5  \
    1 "$(_ "Zen kernel (optimized for desktop)")" \
    2 "$(_ "LTS kernel (long-term support)")" \
    3 "$(_ "Vanilla kernel")" \
    3>&1 1>&2 2>&3 3>&-)

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
        _ "Operation cancelled"
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
DOCUMENTATION_URL="https://github.com/QuasaFoks/QuasarLinux/wiki"
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
echo "Welcome to Quasar Linux!" > /mnt/etc/motd
cd /mnt/bin
ln -sf dash sh
cd

sleep 5
clear

mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /run /mnt/run

_ "Configuring locale..."
if [ -n "$LANG" ]; then
    # 2. Запись через подстановку: заменяем или добавляем
    if grep -q "^LANG=" /mnt/etc/locale.conf 2>/dev/null; then
        # Если строка уже есть — заменяем
        sed -i "s/^LANG=.*/LANG=$LANG/" /mnt/etc/locale.conf
    else
        # Если нет — добавляем
        echo "LANG=$LANG" >> /mnt/etc/locale.conf
    fi
else
    echo "Ошибка: переменная LANG пустая!"
fi
chroot /mnt locale-gen


echo "$(_ "Activating services")"

#MEMSIZE=$(free -g | awk '/Mem:/ {print $2}')

rm /mnt/etc/fstab
fstabgen -U /mnt >> /mnt/etc/fstab

fastzram_install() {
# Читаем ОЗУ в МБ
	RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)

	# 50% от физической рамы, но в рамках [1ГБ ; 16ГБ]
	ZRAM_MB=$(( RAM_MB / 2 ))
	[ $ZRAM_MB -lt 1024 ] && ZRAM_MB=1024
	[ $ZRAM_MB -gt 16384 ] && ZRAM_MB=16384

	git clone https://codeberg.org/QuasarFoks/FastZram.git && cd FastZram && make
	cp fzram /mnt/usr/local/bin
	mkdir -p /mnt/etc/fzram
	printf '{\n  "size": "%s",\n  "algorithm": "lz4",\n  "swap-priority": "100"\n}\n' "$ZRAM_MB" > /mnt/etc/fzram/default.json
	cp init.src/fzram.openrc /mnt/etc/init.d/FastZram
	chmod +x /mnt/etc/init.d/FastZram
}
fastzram_install

# Активация сервисов
#   {service}       {runlevel}
#
#   1) UDEV         sysinit
#   2) FASTZRAM     sysinit
#   3) DBUS         boot
#   4) ELOGIND      boot
#   5) ACPID        default
#
#
######################################################################################
#  udev

_ "Configuring services..."

if chroot /mnt rc-update add udev sysinit; then
    echo "udev$(_ " added to autostart")"
else
    echo "$(_ "Reinstalling ")udev..."
    chroot /mnt pacman -S udev lib32-udev || chroot /mnt pacman -S udev
    chroot /mnt rc-update add udev sysinit
fi

######################################################################################
# fastzram

if chroot /mnt rc-update add FastZram sysinit; then
	echo "fastzram$(_ "added to autostart")"
else
	echo "$(_ "Reinstalling ")fastzram..."
	fastzram_install;
	chroot /mnt rc-update add FastZram sysinit
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
    echo "chrony$(_ " added to autostart")"
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
mkdir /mnt/tmp || true
cd /mnt/tmp

git clone https://github.com/QuasarFoks/Systemd-rc.git
SRC_FILE="Systemd-rc/src/systemctl/openrc/systemctl.go"
go build -o "systemctl" "$SRC_FILE"
cp systemctl /mnt/bin

git clone https://codeberg.org/QuasarFoks/QuasarLinux-service-rules.git
cp QuasarLinux-service-rules/udev_rules/* /mnt/etc/udev/rules.d/
chroot /mnt udevadm control --reload-rules
chroot /mnt udevadm trigger

clear
_ "Installing branding"

wget -O QuasarLinux.tar.bz2 "https://github.com/QuasarFoks/QuasarLinux/releases/download/REV-1.1-image/system-rev-1-1.tar.bz2" || {
    _ "Error: download failed"
    exit 1
}

downloaded_hash=$(sha256sum QuasarLinux.tar.bz2 | cut -d' ' -f1)
expected_hash="ad19f72b38d020e72bf47756e85787687cd35bf711836e973e848dff8c8a5c78"

if [ "$downloaded_hash" = "$expected_hash" ]; then
    _ "Hash check passed"
    tar -xf QuasarLinux.tar.bz2 -C /mnt/
    rm -f /mnt/README 2>/dev/null
else
    echo "$(_ "Hash check failed!")"
    echo "$(_ "Expected: ")$expected_hash"
    echo "$(_ "Got:      ")$downloaded_hash"
    exit 1
fi

_ "Base installation completed!"

unset expected_hash
unset downloaded_hash
