#!/usr/bin/env bash

#  OS: BLAZARLINUX
#  TYPE: Cross building
set -euo pipefail



# Сборка BlazarLinux из исходников
# Сборка идёт строго по книге :
#   Linux From Scratch


export MAKEFLAGS="-j11"
export BLAZAR=/mnt/blazar
export TOOL="$BLAZAR"/tools
export SOURCES="$BLAZAR"/sources
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH="$TOOL/bin:$PATH"

# подготовка переменных

export BINUTILS_S="$SOURCES"/binutils-2.43.1.tar.xz
export BINUTILS_DIR="$SOURCES"/binutils-2.43.1

export GCC_S="$SOURCES"/gcc-14.2.0.tar.xz
export GCC_DIR="$SOURCES"/gcc-14.2.0

export M4_S="$SOURCES"/m4-1.4.19.tar.xz
export M4_DIR="$SOURCES"/m4-1.4.19

export NCURSES_S="$SOURCES"/ncurses-6.5.tar.gz
export NCURSES_DIR="$SOURCES"/ncurses-6.5

export BASH_S="$SOURCES"/bash-5.2.32.tar.gz
export BASH_DIR="$SOURCES"/bash-5.2.32

export COREUTILS_S="$SOURCES"/coreutils-9.5.tar.xz
export COREUTILS_DIR="$SOURCES"/coreutils-9.5

export DIFUT_S="$SOURCES"/diffutils-3.10.tar.xz
export DIFUT_DIR="$SOURCES"/diffutils-3.10

export FILE_S="$SOURCES"/file-5.45.tar.gz
export FILE_DIR="$SOURCES"/file-5.45

export FINDUTILS_S="$SOURCES"/findutils-4.10.0.tar.xz
export FINDUTILS_DIR="$SOURCES"/findutils-4.10.0

export GAWK_S="$SOURCES"/gawk-5.3.0.tar.xz
export GAWK_DIR="$SOURCES"/gawk-5.3.0

export GREP_S="$SOURCES"/grep-3.11.tar.xz
export GREP_DIR="$SOURCES"/grep-3.11

export GZIP_S="$SOURCES"/gzip-1.13.tar.xz
export GZIP_DIR="$SOURCES"/gzip-1.13

export MAKE_S="$SOURCES"/make-4.4.1.tar.gz
export MAKE_DIR="$SOURCES"/make-4.4.1

export PATCH_SOURCES="$SOURCES"/patch-2.7.6.tar.xz
export PATCH_S_DIR="$SOURCES"/patch-2.7.6

export SED_S="$SOURCES"/sed-4.9.tar.xz
export SED_DIR="$SOURCES"/sed-4.9

export TAR_S="$SOURCES"/tar-1.35.tar.xz
export TAR_DIR="$SOURCES"/tar-1.35

export XZ_S="$SOURCES"/xz-5.6.2.tar.xz
export XZ_DIR="$SOURCES"/xz-5.6.2

check_prerequisites() {
    [[ ! -d "$BLAZAR" ]] && { echo "❌ $BLAZAR не существует. Смонтируй раздел!"; exit 1; }
    [[ ! -d "$SOURCES" ]] && { echo "❌ $SOURCES не существует. Загрузи исходники!"; exit 1; }
    command -v patch >/dev/null || { echo "❌ Требуется пакет 'patch'"; exit 1; }
}

extract_packages() {
    local packages=(
        "$BASH_S" "$BINUTILS_S" "$GCC_S" "$M4_S" "$NCURSES_S" "$COREUTILS_S"
        "$DIFUT_S" "$FILE_S" "$FINDUTILS_S" "$GAWK_S" "$GREP_S" "$GZIP_S"
        "$MAKE_S" "$PATCH_SOURCES" "$SED_S" "$TAR_S" "$XZ_S"
    )

    for archive in "${packages[@]}"; do
        [[ ! -f "$archive" ]] && {
            echo "⚠️ Архив не найден: $(basename "$archive")"
            exit 1
        }
        echo "📦 Распаковка: $(basename "$archive")"
        tar -xf "$archive" -C "$SOURCES"
    done
}
m4_build() {
    echo "||||||||||||||||||||||"
    echo "||                  ||"
    echo "||    M4            ||"
    echo "||                  ||"
    echo "||||||||||||||||||||||" 
    cd "$M4_DIR"

    ./configure --prefix=/usr   \
            --disable-doc \
            --disable-nls \
            --host="$LFS_TGT"\
            --disable-dependency-tracking \
            --build=$(build-aux/config.guess)
    make  && make DESTDIR="$BLAZAR" install
}

ncurses_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    NCURSES       ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$NCURSES_DIR"
	sed -i s/mawk// configure
	mkdir build
	pushd build
  		../configure
  		make -C include
  		make -C progs tic
	popd
	./configure --prefix=/usr                \
            --host="$LFS_TGT"             \
            --build="$(./config.guess)"    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping
	make
	make DESTDIR="$BLAZAR" TIC_PATH="$(pwd)/build/progs/tic" install
	ln -sv libncursesw.so "$BLAZAR"/usr/lib/libncurses.so
	sed -e 's/^#if.*XOPEN.*$/#if 1/' \
   		 -i "$BLAZAR"/usr/include/curses.h


}


bash_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||      BASH        ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$BASH_DIR"
    	./configure --prefix=/usr                      \
        	--build=$(sh support/config.guess) \
            	--host="$LFS_TGT"                    \
            	--without-bash-malloc              \
            	bash_cv_strtold_broken=no
    	make  &&  make DESTDIR="$BLAZAR" install
    	cd "$BLAZAR"/bin
    	ln -sv bash sh
    	cd ..
}
coreutils_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    COREUTILS     ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$COREUTILS_DIR"
	./configure --prefix=/usr                     \
            --host="$LFS_TGT"                  \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
	make  && make DESTDIR="$BLAZAR" install



	mv -v "$BLAZAR"/usr/bin/chroot              "$BLAZAR"/usr/sbin
	mkdir -pv "$BLAZAR"/usr/share/man/man8
	mv -v "$BLAZAR"/usr/share/man/man1/chroot.1 "$BLAZAR"/usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/'                    "$BLAZAR"/usr/share/man/man8/chroot.8
}

diffutils_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    DIFUTILS      ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$DIFUT_DIR"
	./configure --prefix=/usr   \
            --host="$LFS_TGT" \
            --build=$(./build-aux/config.guess)
	make  && make DESTDIR="$BLAZAR" install
}
file_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||       FILE       ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$FILE_DIR"
	mkdir build
	pushd build
		../configure --disable-bzlib      \
        	             --disable-libseccomp \
        	             --disable-xzlib      \
        	             --disable-zlib
  		make
	popd
	./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
	make  FILE_COMPILE="$(pwd)/build/src/file"
	make DESTDIR="$BLAZAR" install
	rm -v "$BLAZAR"/usr/lib/libmagic.la
}
findutils_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    FindUTILS     ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$FINDUTILS_DIR"
	./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host="$LFS_TGT"                 \
            --build=$(build-aux/config.guess)
	make  && make DESTDIR="$BLAZAR" install
}
gawk_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    GAWK          ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$GAWK_DIR"
	sed -i 's/extras//' Makefile.in
	./configure --prefix=/usr   \
            --host="$LFS_TGT" \
            --build=$(build-aux/config.guess)
	make  && make DESTDIR="$BLAZAR" install
}
grep_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||     GREP         ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$GREP_DIR"
	./configure --prefix=/usr   \
            --host="$LFS_TGT" \
            --build=$(./build-aux/config.guess)
	make && make DESTDIR="$BLAZAR" install
}

gzip_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||      GZIP        ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$GZIP_DIR"
	./configure --prefix=/usr --host=$LFS_TGT
	make  && make DESTDIR="$BLAZAR" install
}
make_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||      MAKE        ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
	cd "$MAKE_DIR"
	./configure --prefix=/usr   \
            --without-guile \
            --host="$LFS_TGT" \
            --build=$(build-aux/config.guess)
	make  && make DESTDIR="$BLAZAR" install
}

patch_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||      PATCH       ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$PATCH_S_DIR"
	./configure --prefix=/usr   \
            --host="$LFS_TGT" \
            --build=$(build-aux/config.guess)
	make && make DESTDIR="$BLAZAR" install
}
sed_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||       SED        ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$SED_DIR"
    	./configure --prefix=/usr   \
            --host="$LFS_TGT" \
            --build=$(./build-aux/config.guess)
    	make  && make DESTDIR="$BLAZAR" install
}
tar_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    TAR           ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$TAR_DIR"
    	./configure --prefix=/usr                     \
            --host="$LFS_TGT"                \
            --build=$(build-aux/config.guess)
    	make  && make DESTDIR="$BLAZAR" install
}
xz_build() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||      XZ          ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$XZ_DIR"
    	./configure --prefix=/usr                     \
            --host="$LFS_TGT"                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.2
    	make  && make DESTDIR="$BLAZAR" install
    	rm -v "$BLAZAR"/usr/lib/liblzma.la
}
binutils_build_stage_two() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    BINUTILS      ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$BINUTILS_DIR"
    	sed '6009s/$add_dir//' -i ltmain.sh
    	mkdir -v build 2>/dev/null || { rm -rf build && mkdir -v build; }
    	cd       build
    	../configure                   \
        	--prefix=/usr              \
        	--build=$(../config.guess) \
        	--host="$LFS_TGT"            \
        	--disable-nls              \
        	--enable-shared            \
        	--enable-gprofng=no        \
        	--disable-werror           \
        	--enable-64-bit-bfd        \
        	--enable-new-dtags         \
        	--enable-default-hash-style=gnu
    	
    	
    	
    	make 
    	make DESTDIR="$BLAZAR" install
    	rm -v "$BLAZAR"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
}
gcc_build_stage_two() {
	echo "||||||||||||||||||||||"
	echo "||                  ||"
    	echo "||    GCC TWO       ||"
    	echo "||                  ||"
    	echo "||||||||||||||||||||||" 
    	cd "$SOURCES"
    	cd "$GCC_DIR"
    	tar -xf ../mpfr-4.2.1.tar.xz
    	mv -v mpfr-4.2.1 mpfr
    	tar -xf ../gmp-6.3.0.tar.xz
    	mv -v gmp-6.3.0 gmp
    	tar -xf ../mpc-1.3.1.tar.gz
    	mv -v mpc-1.3.1 mpc
    	case "$(uname -m)" in
    	    x86_64)
    	        sed -e '/m64=/s/lib64/lib/' \
   	             -i.orig gcc/config/i386/t-linux64
       	    ;;
    	esac
    	sed '/thread_header =/s/@.*@/gthr-posix.h/' \
        	-i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
    	mkdir -v build || rm -rf build && mkdir -v build
    	cd       build
    	../configure                                       \
        	--build=$(../config.guess)                     \
        	--host=$LFS_TGT                                \
        	--target=$LFS_TGT                              \
        	LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
        	--prefix=/usr                                  \
        	--with-build-sysroot="$BLAZAR"                      \
        	--enable-default-pie                           \
        	--enable-default-ssp                           \
        	--disable-nls                                  \
        	--disable-multilib                             \
        	--disable-libatomic                            \
        	--disable-libgomp                              \
        	--disable-libquadmath                          \
        	--disable-libsanitizer                         \
        	--disable-libssp                               \
        	--disable-libvtv                               \
        	--enable-languages=c,c++
    	make && make DESTDIR="$BLAZAR" install
    	ln -sv gcc "$BLAZAR"/usr/bin/cc
}
info() {
    	cat << EOF
BlazarLinux Building

BETA
EOF
}

main() {
    info
    check_prerequisites
    extract_packages
    m4_build
    ncurses_build
    bash_build
    coreutils_build
    diffutils_build
    file_build
    findutils_build
    gawk_build
    grep_build
    gzip_build
    make_build
    patch_build
    sed_build
    tar_build
    xz_build
    binutils_build_stage_two
    gcc_build_stage_two
    echo ":GOOD JOB!:"
}
main
