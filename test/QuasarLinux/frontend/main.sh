#!/usr/bin/env bash
# /* QuasarFoks
# /* QuasarInstall
# /* GPLv3

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
    _() { printf '%s' "$1"; }
else
    _() { gettext -s "$1"; }
fi

base_pack() {

}




main() {
    dialog --msgbox "$(_ "Welcome to QusaarLinux")" 8 40
    dialog --clear \
        --title "$(_ "Please read the license agreement ")" \
        --backtitle "" \
        --yes-label "Продолжить" \
        --no-label "Отмена" \
        --yesno '\n
Лицензия и Товарные знаки
QuasarLinux является свободным ПО, основанным на Artix Linux. Исходный код распространяется под лицензиями соответствующих компонентов (в основном GPL v2/v3, MIT, BSD).
Ограничения на использование товарных знаков:
Названия "QuasarLinux", "QuasarFoks", "BlazarLinux", "QuasarOS", а также связанные логотипы и графические элементы являются товарными знаками сообщества QuasarFoks.
Запрещается использование указанных товарных знаков в производных работах, форках или сторонних сборках без письменного разрешения QuasarFoks. При создании модифицированных версий вы обязаны:

1. Удалить все логотипы и упоминания бренда Quasar.

2. Переименовать продукт, исключая слово "Quasar".

3. Четко указать, что ваша сборка не связана с официальным проектом QuasarFoks.

Подробнее: https://quasarfoks.github.io/policy
' \
        20 90 \
        >/dev/tty 2>&1 || reboot
    MainChoise=$(dialog --menu "$(_ "Select an edition")" 12 50 5 \
    "1" "REVision" \
    "2" "Second Edition" \
    "3" "PROfessional" 3>&1 1>&2 2>&3 3>&-)
    case $MainChoise in
        1) REV_INSTALL ;;
        2) SE_INSTALL ;;
        3) PRO_INSTALL ;;
        *) ;;
    esac
}
main
