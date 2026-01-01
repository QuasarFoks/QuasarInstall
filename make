#!/usr/bin/env sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_DIR="$SCRIPT_DIR"/build

list_os() {
  echo "
  -- please select OS --
    Операционная система           тип             версия
  1) QuasarLinux                стабильный          3.0
  2) QuasarXOS                  Скоро...            --
  3) BlazarLinux                В разработке        --
  4) QuasarOS                   Скоро...            --
  "
}

build_tools() {
    cd packs/QuasarTools
    mkdir build

    # Fast-chroot
    cd fast-chroot
    chmod +x make && ./make
    cp fchroot ../build
    cd ..
    # Systemd-rc
    cd Systemd-rc
    chmod +x make && ./make
    cp systemctl ../build
    cd ..
    # Перенос в установщик
    cp build/*  "$BUILD_DIR"/quasartools
}

quasarlinux_tui_installer() {
    local QUASARLINUX_INSTALLER=main/QuasarLinux
    local QUASARLINUX_INSTALL_MODULES=main/QuasarLinux/modules
    local QUASARLINUX_INSTALL_PROFILES=profiles/QuasarLinux
    local profiles="$(ls -x --width=1 $QUASARLINUX_INSTALL_PROFILES)"

    # Создание нужных каталогов
    mkdir "$BUILD_DIR"/modules || true
    mkdir "$BUILD_DIR"/packages || true
    mkdir "$BUILD_DIR"/profiles || true
    mkdir "$BUILD_DIR"/quasartools || true
    rm "$BUILD_DIR"/README.md || true

    local MODULES="$BUILD_DIR/modules"

    cp "$QUASARLINUX_INSTALL_MODULES"/bootloader "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/install  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/inst_pack  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/mirrorconfig.sh  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/network  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/parted  "$MODULES"
#    cp "$QUASARLINUX_INSTALL_MODULES"/post  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/region.sh  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/users.sh  "$MODULES"

    go build -o region_settings  "$QUASARLINUX_INSTALL_MODULES"/region_settings.go
    cp region_settings "$MODULES"


    # Копировать содержимое профилей, а не саму директорию
    cp -r "$QUASARLINUX_INSTALL_PROFILES"/* "$BUILD_DIR"/profiles/ 2>/dev/null || {
        echo "Не удалось скопировать профили"
    }
    build_tools


}
main() {
  echo "
  \\\\\\\\\\\\\\\\\\\\\\\\\\\
  \\    Выберите вариант   \\
  \\ 1) QuasarLinux        \\
  \\ 2) QuasarXOS          \\
  \\ 3) BlazarLinux        \\
  \\ 4) QuasarOS           \\
  \\\\\\\\\\\\\\\\\\\\\\\\\\\
  "
  read -p ">>> " CHOISE
  case "$CHOISE" in
    1) quasarlinux_tui_installer ;;
    2) quasarxos_installer ;;
    3) blazarlinux_tui_installer ;;
    4) quasaros_installer ;;
    *) echo "Не вереный выбор"
  esac
}
main
