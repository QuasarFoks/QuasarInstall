#!/usr/bin/env bash
#
# 	BLAZAR LINUX BUILD
#
set -euo pipefail
set -x
# Важные переменные 
export BLAZAR=/mnt/blazar
export TOOL="$BLAZAR"/tools
export SOURCES="$BLAZAR"/sources
export LFS_TGT=$(uname -m)-lfs-linux-gnu

# переменные чтобы не усложнять код
export BINUTILS="$SOURCES"/binutils-2.43.1.tar.xz
export BINUTILS_DIR="$SOURCES"/binutils-2.43.1
export GCC="$SOURCES"/gcc-14.2.0.tar.xz
export GCC_DIR="$SOURCES"/gcc-14.2.0
export LINUX="$SOURCES"/linux-6.10.5.tar.xz
export LINUX_DIR="$SOURCES"/linux-6.10.5
export GLIBC="$SOURCES"/glibc-2.40.tar.xz
export GLIBC_DIR="$SOURCES"/glibc-2.40
export PATH="$BLAZAR/tools/bin:$PATH"
export PATH="$BLAZAR/tools/"$LFS_TGT"/bin:$PATH"

make_rebuild() {
	rm -rf build
	mkdir -v build

}
pre_build() {
	mkdir -v build || make_rebuild
	cd       build

}

binutils_build() {
	cd "$SOURCES"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "+++          binutils              +++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	tar -xf "$BINUTILS"
	cd "$BINUTILS_DIR"
	pre_build


	../configure --prefix="$BLAZAR"/tools \
             --with-sysroot="$BLAZAR" \
             --target=$LFS_TGT   \
             --disable-nls       \
             --disable-gprofng \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
	make -j8 && make install
}
gcc_build() {
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "+++     GCC 14.2.0                 +++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	tar -xf "$GCC"
	cd "$GCC_DIR"
	tar -xf ../mpfr-4.2.1.tar.xz
	mv -v mpfr-4.2.1 mpfr
	tar -xf ../gmp-6.3.0.tar.xz
	mv -v gmp-6.3.0 gmp
	tar -xf ../mpc-1.3.1.tar.gz
	mv -v mpc-1.3.1 mpc


	case $(uname -m) in
 		x86_64)
   			sed -e '/m64=/s/lib64/lib/' \
      	  		-i.orig gcc/config/i386/t-linux64
 		;;
	esac
	pre_build
	../configure                  \
    		--target=$LFS_TGT         \
    		--prefix="$BLAZAR"/tools       \
    		--with-glibc-version=2.40 \
    		--with-sysroot="$BLAZAR"       \
    		--with-newlib             \
    		--without-headers         \
    		--enable-default-pie      \
		--enable-default-ssp      \
  		--disable-nls             \
   		--disable-shared          \
    		--disable-multilib        \
    		--disable-threads         \
    		--disable-libatomic       \
    		--disable-libgomp         \
    		--disable-libquadmath     \
    		--disable-libssp          \
    		--disable-libvtv          \
    		--disable-libstdcxx       \
    		--enable-languages=c,c++
	make -j8 && make install
	cd ..
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
		`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
}
linux_api_build() {
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "+++          linux_api             +++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	tar -xf "$LINUX"
	cd "$LINUX_DIR"
	make mrproper
	make headers
	find usr/include -type f ! -name '*.h' -delete
	#mkdir -pv "$BLAZAR"/usr/include
	cp -rv usr/include "$BLAZAR"/usr/
}
glibc_build() {
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "+++          glibc                 +++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	case $(uname -m) in
		x86_64)
			mkdir -p "$BLAZAR"/lib64
			ln -sfv ../lib/ld-linux-x86-64.so.2 "$BLAZAR"/lib64
			ln -sfv ../lib/ld-linux-x86-64.so.2 "$BLAZAR"/lib64/ld-lsb-x86-64.so.3
			;;
	esac


	tar -xf "$GLIBC"
	cd "$GLIBC_DIR"
	patch -Np1 -i ../glibc-2.40-fhs-1.patch
	pre_build
	echo "rootsbindir=/usr/sbin" > configparms
	../configure                             \
     		--prefix=/usr                      \
      		--host=$LFS_TGT                    \
      		--build=$(../scripts/config.guess) \
      		--enable-kernel=4.19               \
      		--with-headers="$BLAZAR"/usr/include    \
      		--disable-nscd                     \
      		libc_cv_slibdir=/usr/lib
	make -j8 && make DESTDIR="$BLAZAR" install
	sed '/RTLDLIST=/s@/usr@@g' -i "$BLAZAR"/usr/bin/ldd


	echo 'int main(){}' | $LFS_TGT-gcc -xc -
	if readelf -l a.out | grep -q 'ld-linux-x86-64\.so\.2'; then
		echo "glibc готов!"
	else
		echo "чтото пошло не так!"
		exit 1 
	fi

	rm -v a.out
}
libstdc_pp_build() {
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "+++          libstdc_pp            +++"
	echo "++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++++++++++++++++++"

	cd "$GCC_DIR"
	rm -rf build
	pre_build

		../libstdc++-v3/configure           \
    		--host=$LFS_TGT                 \
    		--build=$(../config.guess)      \
    		--prefix=/usr                   \
    		--disable-multilib              \
    		--disable-nls                   \
    		--disable-libstdcxx-pch         \
    		--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
	make -j8 && make DESTDIR="$BLAZAR" install
	rm -v "$BLAZAR"/usr/lib/lib{stdc++{,exp,fs},supc++}.la
}

main() {
	cd "$SOURCES"
	#binutils_build
	cd "$SOURCES"
	#gcc_build
	cd "$SOURCES"
	linux_api_build
	cd "$SOURCES"
	sleep 1
	glibc_build
	cd "$SOURCES"
	libstdc_pp_build
	cd "$SOURCES"
	echo "Тулчейн собран!"
}
main
