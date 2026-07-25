#!/usr/bin/env bash
export VERSION="1.1"
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'
export BRIGHT_WHITE='\033[1;97m$*\033[0m'

info() { echo -e "${BLUE}[info]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} ${1}                                           :("; }
success() { echo -e "${GREEN}[success]${NC} $1"; }

echo_m() { echo -e "\033[1;97m${1}\033[0m"; }


MainLogo() {
    echo_m "
    ╔════════════════════════════════════════════════════════════════╗
    ║                    QuasarFoks Help Center                      ║
    ╚════════════════════════════════════════════════════════════════╝"
}

QRCodes() {
    echo ""
    echo "  📱 QR-КОДЫ ДЛЯ СКАНИРОВАНИЯ"
    echo "  ═══════════════════════════════════════════════════════════"
    echo ""

    # Показываем два QR в ряд
    if [ -f /usr/local/sdk/qr/github-issue.txt ] && [ -f /usr/local/sdk/qr/gitverse-issue.txt ]; then
        paste /usr/local/sdk/qr/github-issue.txt /usr/local/sdk/qr/gitverse-issue.txt
    else
        echo "   QR-коды не найдены!"
        echo "  Ожидаемые файлы:"
        echo "    /usr/local/sdk/qr/github-issue.txt"
        echo "    /usr/local/sdk/qr/gitverse-issue.txt"
    fi

    echo ""
    echo "  Github:  https://github.com/QuasarFoks/QuasarInstall/issues"
    echo "  Gitverse: https://gitverse.ru/quasarfoks/QuasarInstall/tasktracker?view=list"
    echo ""
    echo "  ═══════════════════════════════════════════════════════════"
}

MainMenu() {
    echo ""
    echo "  [1] Local Wiki (Info)"
    echo "  [2] Exit"
    echo ""
    echo "  ═══════════════════════════════════════════════════════════"
}

main() {
    while true; do
        clear
        MainLogo
        QRCodes
        MainMenu

        read -p "  [1-2] >>> " AER

        case "$AER" in
            1)
                clear
                echo "   Запуск Local Wiki..."
                echo ""
                if command -v info &>/dev/null; then
                    /usr/bin/info /usr/local/sdk/Vendor/QuasarInstall 2>/dev/null || \
                    /usr/bin/info -f /usr/local/sdk/Vendor/QuasarInstall.info 2>/dev/null || \
                    echo "    Документация не найдена"
                else
                    echo "    info не установлен!"
                    echo "  Установите: sudo pacman -S texinfo"
                fi
                read -p "  Нажмите Enter для продолжения..."
                ;;
            2)
                clear
                echo "exit"
                exit 0
                ;;
            *)
                echo "  Неверный выбор! Попробуйте снова."
                sleep 1
                ;;
        esac
    done
}

main
