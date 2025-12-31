#!/usr/bin/env sh
export BUILD_DIR=build

echo "
-- please select OS --
  Операционная система           тип             версия
1) QuasarLinux                стабильный          3.0
2) QuasarXOS                  Скоро...            --
3) BlazarLinux                В разработке        --
4) QuasarOS                   Скоро...            --
"
quasarlinux_tui_installer() {
    local QUASARLINUX_INSTALLER="main/QuasarLinux"
    local QUASARLINUX_INSTALL_MODULES="main/QuasarLinux/modules"
    local QUASARLINUX_INSTALL_PROFILES="profiles/QuasarLinux"
    local profiles="$(ls -x --width=1 $QUASARLINUX_INSTALL_PROFILES)"
    mkdir "$BUILD"/modules
    local MODULES="$BUILD/modules"
    cp "$QUASARLINUX_INSTALL_MODULES"/bootloader "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/install  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/inst_pack  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/mirrorconfig.sh  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/network  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/parted  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/post  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/region.sh  "$MODULES"
    cp "$QUASARLINUX_INSTALL_MODULES"/users.sh  "$MODULES"

    go build -o region_settings  region_settings.go




}
