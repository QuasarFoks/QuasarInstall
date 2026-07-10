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

SCRIPT_DIR="/installer/modules"
chmod +x "$SCRIPT_DIR"
express() {
    "$SCRIPT_DIR"/parted.sh
    "$SCRIPT_DIR"/basepack.sh
    #"$SCRIPT_DIR"/mirrorconfig.sh
    "$SCRIPT_DIR"/users.sh
    "$SCRIPT_DIR"/inst_pack.sh
    "$SCRIPT_DIR"/bootloader.sh


}

regions() {
    cd "$SCRIPT_DIR"
}

parted_menu() {
    "$SCRIPT_DIR"/parted.sh
}

user() {
    "$SCRIPT_DIR"/users.sh
}


android_install() {
    "$SCRIPT_DIR"/userland/android_install # временно не будет работать :(
}

wine_install() {
    "$SCRIPT_DIR"/userland/wine_config.sh || "$SCRIPT_DIR"/userland/wine_config
}

audio_config() {
    "$SCRIPT_DIR"/userland/audio_config.sh || "$SCRIPT_DIR"/userland/audio_config
}

browser_install() {
    "$SCRIPT_DIR"/userland/browser_config.sh || "$SCRIPT_DIR"/userland/browser_config
}

office_install() {
    "$SCRIPT_DIR"/userland/office_config.sh || "$SCRIPT_DIR"/userland/office_config
}

backup_system() {
    "$SCRIPT_DIR"/userland/backup_system.sh
}

clean_system() {
    "$SCRIPT_DIR"/userland/clean_full.sh
}


while true; do
    seting=$(dialog --title "$(_ "Quasar-install")" --menu "$(_ "Select option:")" 15 70 7 \
    1 "$(_ "Express setup")" \
    2 "$(_ "Partitioning")" \
    3 "$(_ "Install base system")" \
    4 "$(_ "Install packages")" \
    5 "$(_ "User setup")" \
    6 "$(_ "Install bootloader")" \
    7 "$(_ "Audio")" \
    8 "$(_ "Wine")" \
    9 "$(_ "Web browser")" \
    10 "$(_ "Region")" \
    11 "$(_ "Office")" \
    12 "$(_ "Exit")" \
    3>&1 1>&2 2>&3 3>&-)

    [ $? -ne 0 ] && break   # если жмём ESC/Cancel → выход

    case $seting in
        1) express ;;
        2) parted_menu ;;
        3) "$SCRIPT_DIR/basepack.sh" ;;
        4) "$SCRIPT_DIR/inst_pack.sh" ;;
        5) user ;;
        6) "$SCRIPT_DIR/bootloader.sh" ;;
        7) audio_config ;;
        8) wine_install ;;
        9) browser_install ;;
        10) region ;;
        11) office_install ;;
        12) break ;;
    esac
done
