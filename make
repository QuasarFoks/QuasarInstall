#!/usr/bin/env sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_DIR="$SCRIPT_DIR"/build
mkdir -p "$BUILD_DIR"

list_os() {
  echo "
  -- please select OS --
    Операционная система           тип             версия установщика
  1) QuasarLinux                стабильный          3.0
  2) QuasarXOS                  Скоро...            --
  3) BlazarLinux                В разработке        --
  4) QuasarOS                   Скоро...            --
  "
}
edition_quasarlinux() {
    echo "
  -- please select OS --
    Операционная система           тип              версия дистрибутива
------------------------------------------------------------
  1) Second Edition               Скоро               0.1
  2) REVision                   Стабильная            1.1
  3) PRO                          Скоро               -.-
------------------------------------------------------------
  "
  read -p ">>> " CHOISE_EDITION
  case "$CHOISE_EDITION" in
    1) quasarlinux_se_installer ;;
    2) quasarlinux_rev_installer ;;
    3) quasarlinux_pro_installer ;;
    *) echo "Не вереный выбор"
  esac

}



build_tools() {
    cd packs/QuasarTools
    mkdir build || true

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






quasarlinux_rev_installer() {
    rm -rf "$BUILD_DIR"/* || true
    local QUASARLINUX_INSTALLER="main/QuasarLinux/REV"
    local QUASARLINUX_INSTALL_MODULES="$QUASARLINUX_INSTALLER/modules"
    local QUASARLINUX_INSTALL_MODULES_USERLAND="$QUASARLINUX_INSTALLER/userland"
    local QUASARLINUX_INSTALL_PROFILES="profiles/QuasarLinux"
    local profiles="$(ls -x --width=1 $QUASARLINUX_INSTALL_PROFILES)"

    # Создание нужных каталогов
    mkdir "$BUILD_DIR"/modules || true
    mkdir "$BUILD_DIR"/tools || true
    mkdir "$BUILD_DIR"/packages || true
    mkdir "$BUILD_DIR"/profiles || true
    mkdir "$BUILD_DIR"/quasartools || true
    mkdir "$BUILD_DIR"/image || true

    local MODULES="$BUILD_DIR/modules"
    cp -r "$SCRIPT_DIR"/packs/language "$BUILD_DIR"

    cp "$QUASARLINUX_INSTALL_MODULES"/bootloader "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/basepack "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/install  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/inst_pack  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/mirrorconfig.sh  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/network  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/parted  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/region  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/users.sh  "$MODULES"
    cp -r "$QUASARLINUX_INSTALL_MODULES"/userland  "$MODULES"

    go build -o region_settings  "$QUASARLINUX_INSTALL_MODULES"/region_settings.go
    cp region_settings "$MODULES" || true


    # Копировать содержимое профилей, а не саму директорию
    cp -r "$QUASARLINUX_INSTALL_PROFILES"/* "$BUILD_DIR"/profiles/ 2>/dev/null || {
        echo "Не удалось скопировать профили"
    }
    build_tools
    local RUNFILE="$SCRIPT_DIR/main/QuasarLinux/REV/run"
    chmod +x "$RUNFILE"
    cp "$RUNFILE" "$BUILD_DIR"

    chmod +x "$MODULES"/*
    chmod +x "$MODULES"/userland/*

}
main() {
  list_os

  read -p ">>> " CHOISE
  case "$CHOISE" in
    1) edition_quasarlinux ;;
    2) quasarxos_installer ;;
    3) blazarlinux_tui_installer ;;
    4) quasaros_installer ;;
    *) echo "Не вереный выбор"
  esac
}
main
