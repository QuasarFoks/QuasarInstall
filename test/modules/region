#!/bin/bash
set -euo pipefail

# Функция создания mirrorlist по региону
create_mirrorlist() {
    local region="$1"
    local mirrorlist_file="/mnt/etc/pacman.d/mirrorlist"
    rm "$mirrorlist_file"
    touch "$mirrorlist_file"
    echo "##" > "$mirrorlist_file"
    echo "## Artix Linux repository mirrorlist" >> "$mirrorlist_file"
    echo "## Region: $region" >> "$mirrorlist_file"
    echo "## Generated on $(date)" >> "$mirrorlist_file"
    echo "##" >> "$mirrorlist_file"
    echo "" >> "$mirrorlist_file"
    
    case "$region" in
        "europe")
            echo "# Europe" >> "$mirrorlist_file"
            echo "Server = https://mirrors.dotsrc.org/artix-linux/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.group.one/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.pascalpuffke.de/artix-linux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://artix.sakamoto.pl/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://ftp.ludd.ltu.se/mirrors/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://artix.kurdy.org/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.vinehost.net/artix-linux/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        
        "asia")
            echo "# Asia" >> "$mirrorlist_file"
            echo "Server = https://mirrors.tuna.tsinghua.edu.cn/artixlinux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirrors.aliyun.com/artixlinux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.nju.edu.cn/artixlinux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://www.miraa.jp/artix-linux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.funami.tech/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.freedif.org/Artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        
        "north-america")
            echo "# North America" >> "$mirrorlist_file"
            echo "Server = https://artix.wheaton.edu/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.clarkson.edu/artix-linux/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirrors.rit.edu/artixlinux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirrors.ocf.berkeley.edu/artix-linux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.csclub.uwaterloo.ca/artixlinux/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        
        "south-america")
            echo "# South America" >> "$mirrorlist_file"
            echo "Server = https://mirror1.cl.netactuate.com/artix/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        
        "oceania")
            echo "# Oceania" >> "$mirrorlist_file"
            echo "Server = https://mirror.aarnet.edu.au/pub/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
        
        "global")
            echo "# Global (fallback)" >> "$mirrorlist_file"
            echo "Server = https://mirror.clarkson.edu/artix-linux/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirrors.dotsrc.org/artix-linux/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://mirror.pascalpuffke.de/artix-linux/\$repo/os/\$arch" >> "$mirrorlist_file"
            echo "Server = https://ftp.ludd.ltu.se/mirrors/artix/\$repo/os/\$arch" >> "$mirrorlist_file"
            ;;
    esac
    
    echo "" >> "$mirrorlist_file"
    echo "# Fallback" >> "$mirrorlist_file"
    echo "Server = https://mirror.clarkson.edu/artix-linux/repos/\$repo/os/\$arch" >> "$mirrorlist_file"
}

# Диалог выбора региона через dialog
region=$(dialog --title "Select Region" \
                --menu "Choose your geographical region for mirrorlist:" \
                15 50 6 \
                1 "Europe" \
                2 "Asia" \
                3 "North America" \
                4 "South America" \
                5 "Oceania" \
                6 "Global (recommended)" \
                3>&1 1>&2 2>&3 3>&-)

case $region in
    1) create_mirrorlist "europe" ;;
    2) create_mirrorlist "asia" ;;
    3) create_mirrorlist "north-america" ;;
    4) create_mirrorlist "south-america" ;;
    5) create_mirrorlist "oceania" ;;
    6) create_mirrorlist "global" ;;
    *) echo "Selection cancelled"; exit 1 ;;
esac

clear
echo "Mirrorlist has been configured for selected region!"
echo "You can run 'sudo pacman -Syy' to update database."
