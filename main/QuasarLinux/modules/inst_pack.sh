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

SRC="/installer"
clear
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /run /mnt/run
main() {
    chroot /mnt pacman -Syy
    prefix=$(dialog --title "$(_ "Quasar-install")" --menu "$(_ "Select option:")" 15 70 7 \
    1 "$(_ "Custom")" \
    2 "$(_ "AI prefix")" \
    3 "$(_ "Gaming prefix")" \
    4 "$(_ "Default prefix")" \
    3>&1 1>&2 2>&3 3>&-)
    case $prefix in
        1) "$SRC"/profiles/custom/custom.sh ;;
        2) "$SRC"/profiles/ai/ai.sh ;;
        3) "$SRC"/profiles/gaming/gaming.sh ;;
        4) "$SRC"/profiles/default/default.sh ;;
    esac
}
main
