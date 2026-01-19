#!/bin/bash

#############################
##  QuasarBuilder          ##
##  by: QuasarFoks         ##
##  os: BlazarLinux        ##
##  type: Download sources ##
#############################


export BLAZAR=/mnt/blazar
export TOOL="$BLAZAR"/tool
export SOURCES="$BLAZAR"/sources

packages=(
    "https://repo.linuxfromscratch.ru/lfs/12.2/acl-2.3.2.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/attr-2.5.2.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/autoconf-2.72.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/automake-1.17.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/bash-5.2.32.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/bc-6.7.6.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/binutils-2.43.1.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/bison-3.8.2.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/bzip2-1.0.8-install_docs-1.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/bzip2-1.0.8.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/check-0.15.2.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/coreutils-9.5-i18n-2.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/coreutils-9.5.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/dbus-1.14.10.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/dejagnu-1.6.3.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/diffutils-3.10.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/e2fsprogs-1.47.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/elfutils-0.191.tar.bz2"
    "https://repo.linuxfromscratch.ru/lfs/12.2/expat-2.6.2.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/expect-5.45.4-gcc14-1.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/expect5.45.4.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/file-5.45.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/findutils-4.10.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/flex-2.6.4.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/flit_core-3.9.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gawk-5.3.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gcc-14.2.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gdbm-1.24.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gettext-0.22.5.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/glibc-2.40-fhs-1.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/glibc-2.40.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gmp-6.3.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gperf-3.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/grep-3.11.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/groff-1.23.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/grub-2.12.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/gzip-1.13.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/iana-etc-20240806.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/inetutils-2.5.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/intltool-0.51.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/iproute2-6.10.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/jinja2-3.1.4.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/kbd-2.6.4-backspace-1.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/kbd-2.6.4.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/kmod-33.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/less-661.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/lfs-bootscripts-20240825.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/libcap-2.70.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/libffi-3.4.6.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/libpipeline-1.5.7.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/libtool-2.4.7.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/libxcrypt-4.4.36.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/linux-6.10.5.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/lz4-1.10.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/m4-1.4.19.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/make-4.4.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/man-db-2.12.1.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/man-pages-6.9.1.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/MarkupSafe-2.1.5.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/meson-1.5.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/mpc-1.3.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/mpfr-4.2.1.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/ncurses-6.5.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/ninja-1.12.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/openssl-3.3.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/patch-2.7.6.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/perl-5.40.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/pkgconf-2.3.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/procps-ng-4.0.4.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/psmisc-23.7.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/python-3.12.5-docs-html.tar.bz2"
    "https://repo.linuxfromscratch.ru/lfs/12.2/Python-3.12.5.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/readline-8.2.13.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/sed-4.9.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/setuptools-72.2.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/shadow-4.16.0.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/sysklogd-2.6.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/systemd-256.4.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/systemd-man-pages-256.4.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/sysvinit-3.10-consolidated-1.patch"
    "https://repo.linuxfromscratch.ru/lfs/12.2/sysvinit-3.10.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/tar-1.35.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/tcl8.6.14-html.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/tcl8.6.14-src.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/texinfo-7.1.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/tzdata2024a.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/udev-lfs-20230818.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/util-linux-2.40.2.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/vim-9.1.0660.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/wheel-0.44.0.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/XML-Parser-2.47.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/xz-5.6.2.tar.xz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/zlib-1.3.1.tar.gz"
    "https://repo.linuxfromscratch.ru/lfs/12.2/zstd-1.5.6.tar.gz"
)

for url in "${packages[@]}"; do
    echo "Downloading $(basename "$url")..."
    if ! wget -nc -P "$SOURCES" "$url"; then
        echo "❌ Failed: $url" >&2
        exit 1
    fi
done
echo "✅ All packages downloaded."
