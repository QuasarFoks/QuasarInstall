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

Europe() {
    regions=($(ls /mnt/usr/share/zoneinfo/Europe/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Europe/"$selected" /mnt/etc/localtime
}
Asia() {
    regions=($(ls /mnt/usr/share/zoneinfo/Asia/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Asia/"$selected" /mnt/etc/localtime
}
US() {
    regions=($(ls /mnt/usr/share/zoneinfo/America/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/America/"$selected" /mnt/etc/localtime
}

Africa() {
    regions=($(ls /mnt/usr/share/zoneinfo/Africa/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Africa/"$selected" /mnt/etc/localtime
}
Antarctica() {
    regions=($(ls /mnt/usr/share/zoneinfo/Antarctica/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Antarctica/"$selected" /mnt/etc/localtime
}

Arctic() {
    regions=($(ls /mnt/usr/share/zoneinfo/Arctic/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Arctic/"$selected" /mnt/etc/localtime
}

Atlantic() {
    regions=($(ls /mnt/usr/share/zoneinfo/Atlantic/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Atlantic/"$selected" /mnt/etc/localtime
}

Australia() {
    regions=($(ls /mnt/usr/share/zoneinfo/Australia/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Australia/"$selected" /mnt/etc/localtime
}

Brazil() {
    regions=($(ls /mnt/usr/share/zoneinfo/Brazil/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Brazil/"$selected" /mnt/etc/localtime
}

Canada() {
    regions=($(ls /mnt/usr/share/zoneinfo/Canada/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Canada/"$selected" /mnt/etc/localtime
}

Etc() {
    regions=($(ls /mnt/usr/share/zoneinfo/Etc/))
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done
    selected=$(dialog --stdout --radiolist "$(_ "Select region:")" 30 40 10       "${checklist_items[@]}")
    clear
    sudo ln -s /usr/share/zoneinfo/Etc/"$selected" /mnt/etc/localtime
}
case $1 in
    Europe) Europe ;;
    Asia) Asia ;;
    US) US ;;
    Africa) Africa ;;
    Antarctica) Antarctica ;;
    Arctic) Arctic ;;
    Atlantic) Atlantic ;;
    Australia) Australia ;;
    Brazil) Brazil ;;
    Canada) Canada ;;
    Etc) Etc ;;
    *) echo "$(_ "No matching region found")" ;;
esac
