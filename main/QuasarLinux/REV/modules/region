#!/bin/bash


Europe() {
    # Получаем список файлов (регионов)
    regions=($(ls /usr/share/zoneinfo/Europe/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Europe/"$selected" /etc/localtime
}
Asia() {
    # Получаем список файлов (регионов)
    regions=($(ls /usr/share/zoneinfo/Asia/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Asia/"$selected" /etc/localtime
}
US() {
    regions=($(ls /usr/share/zoneinfo/America/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/America/"$selected" /etc/localtime
}

Africa() {
    regions=($(ls /usr/share/zoneinfo/Africa/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Africa/"$selected" /etc/localtime
}
Antarctica() {
    regions=($(ls /usr/share/zoneinfo/Antarctica/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Antarctica/"$selected" /etc/localtime
}

Arctic() {
    regions=($(ls /usr/share/zoneinfo/Arctic/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Arctic/"$selected" /etc/localtime
}

Atlantic() {
    regions=($(ls /usr/share/zoneinfo/Atlantic/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Atlantic/"$selected" /etc/localtime
}

Australia() {
    regions=($(ls /usr/share/zoneinfo/Australia/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Australia/"$selected" /etc/localtime
}

Brazil() {
    regions=($(ls /usr/share/zoneinfo/Brazil/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Brazil/"$selected" /etc/localtime
}

Canada() {
    regions=($(ls /usr/share/zoneinfo/Canada/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Canada/"$selected" /etc/localtime
}

Etc() {
    regions=($(ls /usr/share/zoneinfo/Etc/))

    # Формируем строку для dialog (tag, item, status)
    checklist_items=()
    for region in "${regions[@]}"; do
        checklist_items+=("$region" "$region" "off")
    done

    # Вызываем dialog с checklist
    selected=$(dialog --stdout --radiolist "Выберите регионы:" 30 40 10 \
      "${checklist_items[@]}")

    clear
    sudo ln -s /usr/share/zoneinfo/Etc/"$selected" /etc/localtime
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
    *) echo "Нету подходящего региона" ;;
esac
