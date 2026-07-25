#!/bin/bash

# Выбор языка через dialog
LANG_CHOICE=$(dialog --clear \
    --title "Language Selection" \
    --menu "Please select your language:" \
    45 90 20 \
    1 "German (Deutsch)" \
    2 "English" \
    3 "Spanish (Español)" \
    4 "French (Français)" \
    5 "Italian (Italiano)" \
    6 "Japanese (日本語) [beta]" \
    7 "Portuguese (Português)" \
    8 "Russian (Русский)" \
    9 "Turkish (Türkçe)" \
    10 "Chinese (中文) [beta]" \
    11 "Arabic (العربية)" \
    12 "Dutch (Nederlands)" \
    13 "Korean (한국어)" \
    14 "Polish (Polski)" \
    15 "Ukrainian (Українська)" \
    16 "Czech (Čeština)" \
    17 "Greek (Ελληνικά)" \
    18 "Hungarian (Magyar)" \
    19 "Swedish (Svenska)" \
    20 "Finnish (Suomi)" \
    21 "Indonesian (Bahasa Indonesia)" \
    22 "Vietnamese (Tiếng Việt)" \
    23 "Romanian (Română)" \
    24 "Bulgarian (Български)" \
    25 "Slovak (Slovenčina)" \
    26 "Croatian (Hrvatski)" \
    27 "Serbian (Српски)" \
    28 "Catalan (Català)" \
    29 "Norwegian (Norsk)" \
    30 "Danish (Dansk)" \
    3>&1 1>&2 2>&3 3>&-)

# Проверка, что пользователь выбрал (не нажал Cancel)
if [ $? -ne 0 ] || [ -z "$LANG_CHOICE" ]; then
    echo "No language selected. Using English (default)."
    LANG="en_US.UTF-8"
else
    case "$LANG_CHOICE" in
        1)  export LANG="de_DE.UTF-8" ;;
        2)  export LANG="en_US.UTF-8" ;;
        3)  export LANG="es_ES.UTF-8" ;;
        4)  export LANG="fr_FR.UTF-8" ;;
        5)  export LANG="it_IT.UTF-8" ;;
        6)  export LANG="ja_JP.UTF-8" ;;
        7)  export LANG="pt_BR.UTF-8" ;;
        8)  export LANG="ru_RU.UTF-8" ;;
        9)  export LANG="tr_TR.UTF-8" ;;
        10) export LANG="zh_CN.UTF-8" ;;
        11) export LANG="ar_EG.UTF-8" ;;
        12) export LANG="nl_NL.UTF-8" ;;
        13) export LANG="ko_KR.UTF-8" ;;
        14) export LANG="pl_PL.UTF-8" ;;
        15) export LANG="uk_UA.UTF-8" ;;
        16) export LANG="cs_CZ.UTF-8" ;;
        17) export LANG="el_GR.UTF-8" ;;
        18) export LANG="hu_HU.UTF-8" ;;
        19) export LANG="sv_SE.UTF-8" ;;
        20) export LANG="fi_FI.UTF-8" ;;
        21) export LANG="id_ID.UTF-8" ;;
        22) export LANG="vi_VN.UTF-8" ;;
        23) export LANG="ro_RO.UTF-8" ;;
        24) export LANG="bg_BG.UTF-8" ;;
        25) export LANG="sk_SK.UTF-8" ;;
        26) export LANG="hr_HR.UTF-8" ;;
        27) export LANG="sr_RS.UTF-8" ;;
        28) export LANG="ca_ES.UTF-8" ;;
        29) export LANG="no_NO.UTF-8" ;;
        30) export LANG="da_DK.UTF-8" ;;
        *)
            export LANG="en_US.UTF-8"
            ;;
    esac
fi

# Экспортируем переменные
# После определения LANG
echo "export LANG=\"$LANG\"" > "$HOME/.quasar-lang"
echo "export LC_ALL=\"$LANG\"" >> "$HOME/.quasar-lang"
echo "export LC_MESSAGES=\"$LANG\"" >> "$HOME/.quasar-lang"

