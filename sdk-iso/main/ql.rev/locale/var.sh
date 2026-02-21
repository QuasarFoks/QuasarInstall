#!/bin/bash

# Скрипт для создания всех файлов переводов
# Запуск: ./create_translations.sh

set -e  # выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Директория для переводов
LOCALE_DIR="."

# Список языков
declare -A LANGUAGES=(
    ["de_DE"]="Немецкий"
    ["en_US"]="Английский"
    ["es_ES"]="Испанский"
    ["fr_FR"]="Французский"
    ["it_IT"]="Итальянский"
    ["ja_JP"]="Японский"
    ["pt_BR"]="Португальский (Бразилия)"
    ["ru_RU"]="Русский"
    ["tr_TR"]="Турецкий"
    ["zh_CN"]="Китайский (упрощенный)"
)

# Функция создания .po файла
create_po_file() {
    local lang=$1
    local po_file="${lang}.po"

    echo -e "${YELLOW}Создаю ${po_file}...${NC}"

    cat > "$po_file" << EOF
msgid ""
msgstr ""
"Project-Id-Version: installer\n"
"POT-Creation-Date: $(date +'%Y-%m-%d %H:%M%z')\n"
"PO-Revision-Date: $(date +'%Y-%m-%d %H:%M%z')\n"
"Last-Translator: Auto-generated\n"
"Language-Team: ${LANGUAGES[$lang]}\n"
"Language: ${lang}\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

EOF

    # Добавляем все строки для перевода
    cat >> "$po_file" << 'EOF'
msgid "Select disk"
msgstr ""

msgid "Enter disk name (e.g. sda/nvme0n1): "
msgstr ""

msgid "Error: disk"
msgstr ""

msgid "does not exist!"
msgstr ""

msgid "Enter ROOT partition (e.g. sda2): "
msgstr ""

msgid "Enter EFI partition (e.g. sda1): "
msgstr ""

msgid "If no partition, leave empty"
msgstr ""

msgid "Enter BOOT partition (sda1/nvmen1p1): "
msgstr ""

msgid "skipping"
msgstr ""

msgid "Separate /home partition? (y/n): "
msgstr ""

msgid "Enter HOME partition (e.g. sda2): "
msgstr ""

msgid "Separate /var partition? (y/n): "
msgstr ""

msgid "Enter /var partition (e.g. sda2): "
msgstr ""

msgid "Separate /usr partition? (y/n): "
msgstr ""

msgid "Enter /usr partition (e.g. sda2): "
msgstr ""
EOF

    echo -e "${GREEN}✓ Создан ${po_file}${NC}"
}

# Функция создания структуры папок и компиляции
setup_language() {
    local lang=$1
    local lang_dir="$LOCALE_DIR/$lang/LC_MESSAGES"

    echo -e "${YELLOW}Настраиваю ${lang}...${NC}"

    # Создаем директорию
    mkdir -p "$lang_dir"

    # Копируем .po файл если он существует
    if [ -f "${lang}.po" ]; then
        cp "${lang}.po" "$lang_dir/installer.po"
        echo -e "${GREEN}✓ .po файл скопирован${NC}"

        # Компилируем .mo файл
        if command -v msgfmt &> /dev/null; then
            msgfmt "$lang_dir/installer.po" -o "$lang_dir/installer.mo"
            echo -e "${GREEN}✓ .mo файл скомпилирован${NC}"
        else
            echo -e "${RED}✗ msgfmt не найден, .mo не скомпилирован${NC}"
        fi
    else
        echo -e "${RED}✗ Файл ${lang}.po не найден${NC}"
    fi
}

# Функция заполнения перевода для русского (как пример)
fill_russian_translation() {
    local lang="ru_RU"
    local po_file="${lang}.po"

    if [ -f "$po_file" ]; then
        echo -e "${YELLOW}Заполняю русский перевод...${NC}"

        # Создаем временный файл с переводами
        cat > "${po_file}.tmp" << 'EOF'
msgid ""
msgstr ""
"Project-Id-Version: installer\n"
"POT-Creation-Date: 2024-01-01\n"
"PO-Revision-Date: 2024-01-01\n"
"Last-Translator: Auto-generated\n"
"Language-Team: Русский\n"
"Language: ru_RU\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

msgid "Select disk"
msgstr "Выберите диск"

msgid "Enter disk name (e.g. sda/nvme0n1): "
msgstr "Введите имя диска (например, sda/nvme0n1): "

msgid "Error: disk"
msgstr "Ошибка: диск"

msgid "does not exist!"
msgstr "не существует!"

msgid "Enter ROOT partition (e.g. sda2): "
msgstr "Введите раздел для ROOT (например, sda2): "

msgid "Enter EFI partition (e.g. sda1): "
msgstr "Введите раздел для EFI (например, sda1): "

msgid "If no partition, leave empty"
msgstr "При отсутствии раздела оставьте поле пустым"

msgid "Enter BOOT partition (sda1/nvmen1p1): "
msgstr "Введите раздел для BOOT (sda1/nvmen1p1): "

msgid "skipping"
msgstr "пропускаем"

msgid "Separate /home partition? (y/n): "
msgstr "/home отдельный раздел? (y/n): "

msgid "Enter HOME partition (e.g. sda2): "
msgstr "Введите раздел для HOME (например, sda2): "

msgid "Separate /var partition? (y/n): "
msgstr "/var отдельный раздел? (y/n): "

msgid "Enter /var partition (e.g. sda2): "
msgstr "Введите раздел для /var (например, sda2): "

msgid "Separate /usr partition? (y/n): "
msgstr "/usr отдельный раздел? (y/n): "

msgid "Enter /usr partition (e.g. sda2): "
msgstr "Введите раздел для /usr (например, sda2): "
EOF

        mv "${po_file}.tmp" "$po_file"
        echo -e "${GREEN}✓ Русский перевод заполнен${NC}"
    fi
}

# Основная функция
main() {
    echo -e "${GREEN}=== Создание файлов переводов ===${NC}"
    echo ""

    # Создаем .po файлы для каждого языка
    for lang in "${!LANGUAGES[@]}"; do
        create_po_file "$lang"
    done

    echo ""
    echo -e "${YELLOW}Заполняю русский перевод (как пример)...${NC}"
    fill_russian_translation

    echo ""
    echo -e "${GREEN}=== Настройка структуры папок ===${NC}"
    echo ""

    # Создаем структуру и компилируем
    for lang in "${!LANGUAGES[@]}"; do
        setup_language "$lang"
        echo ""
    done

    echo -e "${GREEN}=== Готово! ===${NC}"
    echo ""
    echo "Структура создана:"
    tree "$LOCALE_DIR" 2>/dev/null || ls -la "$LOCALE_DIR"/*
    echo ""
    echo -e "${YELLOW}Для заполнения остальных переводов отредактируйте файлы:${NC}"
    for lang in "${!LANGUAGES[@]}"; do
        echo "  - ${lang}.po"
    done
}

# Проверка наличия tree для красивого вывода
if ! command -v tree &> /dev/null; then
    echo -e "${YELLOW}Установите tree для красивого вывода: sudo apt install tree${NC}"
fi

# Запуск
main
