#!/usr/bin/env bash
set -euo pipefail

# --- Локализация ---
export TEXTDOMAIN="installer"
export TEXTDOMAINDIR="/usr/local/sdk/global/locale"
_() { gettext -s "$1"; }

create_mirrorlist() {
    local region="$1"
    local mirrorlist_file="/mnt/etc/pacman.d/mirrorlist"

    # Создаем шапку
    {
        echo "##"
        echo "## Artix Linux repository mirrorlist"
        echo "## $(_ "Region:") $region"
        echo "## $(_ "Generated on") $(date)"
        echo "##"
        echo ""
    } > "$mirrorlist_file"

    # Основные серверы
    case "$region" in
        "europe")
            cat >> "$mirrorlist_file" << 'EOF'
# Europe
Server = https://mirrors.dotsrc.org/artix-linux/repos/$repo/os/$arch
Server = https://mirror.group.one/artix/$repo/os/$arch
Server = https://mirror.pascalpuffke.de/artix-linux/$repo/os/$arch
Server = https://artix.sakamoto.pl/$repo/os/$arch
Server = https://ftp.ludd.ltu.se/mirrors/artix/$repo/os/$arch
Server = https://artix.kurdy.org/$repo/os/$arch
Server = https://mirror.vinehost.net/artix-linux/$repo/os/$arch
EOF
            ;;
        "asia")
            cat >> "$mirrorlist_file" << 'EOF'
# Asia
Server = https://mirrors.tuna.tsinghua.edu.cn/artixlinux/$repo/os/$arch
Server = https://mirrors.aliyun.com/artixlinux/$repo/os/$arch
Server = https://mirror.nju.edu.cn/artixlinux/$repo/os/$arch
Server = https://www.miraa.jp/artix-linux/$repo/os/$arch
Server = https://mirror.funami.tech/artix/$repo/os/$arch
Server = https://mirror.freedif.org/Artix/$repo/os/$arch
EOF
            ;;
        "north-america")
            cat >> "$mirrorlist_file" << 'EOF'
# North America
Server = https://artix.wheaton.edu/repos/$repo/os/$arch
Server = https://mirror.clarkson.edu/artix-linux/repos/$repo/os/$arch
Server = https://mirrors.rit.edu/artixlinux/$repo/os/$arch
Server = https://mirrors.ocf.berkeley.edu/artix-linux/$repo/os/$arch
Server = https://mirror.csclub.uwaterloo.ca/artixlinux/$repo/os/$arch
EOF
            ;;
        "south-america")
            echo "Server = https://mirror1.cl.netactuate.com/artix/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        "oceania")
            echo "Server = https://mirror.aarnet.edu.au/pub/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        "global")
            cat >> "$mirrorlist_file" << 'EOF'
# Global
Server = https://mirror.clarkson.edu/artix-linux/repos/$repo/os/$arch
Server = https://mirrors.dotsrc.org/artix-linux/repos/$repo/os/$arch
Server = https://mirror.pascalpuffke.de/artix-linux/$repo/os/$arch
Server = https://ftp.ludd.ltu.se/mirrors/artix/$repo/os/$arch
EOF
            ;;
    esac

    # Общий футер (Fallback)
    {
        echo ""
        echo "# Fallback"
        echo "Server = https://mirror.clarkson.edu/artix-linux/repos/\$repo/os/\$arch"
    } >> "$mirrorlist_file"
}

# Диалог выбора региона
region_choice=$(dialog --title "$(_ "Select Region")" \
                --menu "$(_ "Choose your geographical region for mirrorlist:")" \
                15 50 6 \
                1 "Europe" \
                2 "Asia" \
                3 "North America" \
                4 "South America" \
                5 "Oceania" \
                6 "Global (recommended)" \
                3>&1 1>&2 2>&3 3>&-)

case "$region_choice" in
    1) create_mirrorlist "europe" ;;
    2) create_mirrorlist "asia" ;;
    3) create_mirrorlist "north-america" ;;
    4) create_mirrorlist "south-america" ;;
    5) create_mirrorlist "oceania" ;;
    6) create_mirrorlist "global" ;;
    *) echo "$(_ "Selection cancelled")"; exit 1 ;;
esac

clear
echo "$(_ "Mirrorlist has been configured for selected region!")"
echo "$(_ "You can run 'sudo pacman -Syy' to update database.")"
