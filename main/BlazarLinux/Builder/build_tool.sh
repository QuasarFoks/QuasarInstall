#!/usr/bin/env bash
#############################
##  QuasarBuilder          ##
##  by: QuasarFoks         ##
##  os: QuasarLinux        ##
##  type: toolchane build  ##
#############################

# Важные переменные 
export BLAZAR=/mnt/blazar
export TOOL="$BLAZAR"/tool
export SOURCES="$BLAZAR"/sources

# переменные чтобы не усложнять код
export BINUTILS="$SOURCES"/binutils-2.43.1.tar.xz
export BINUTILS_DIR="$SOURCES"/binutils-2.43.1
export GCC="$SOURCES"/gcc.14.2.0.tar.xz
export GCC_DIR="$SOURCES"/gcc.14.2.0
export LINUX="$SOURCES"/linux-6.10.5.tar.xz
export LINUX_DIR="$SOURCES"/linux-6.10.5
export GLIBC="$SOURCES"/glibc-2.40.tar.xz
export GLIBC_DIR="$SOURCES"/glibc-2.40

pre_build() {
	mkdir -v build | make clean
	cd       build
	make clean | true

}

binutils_build() {
	tar -xf "$BINUTILS"
	cd "$BINUTILS_DIR"

	mkdir -v build
	cd       build

	../configure --prefix="$BLAZAR"/tools \
             --with-sysroot="$BLAZAR" \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
	make && make install
}
gcc_build() {
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
	make && make install
	cd ..
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
		`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
}
linux_api_build() {
	tar -xf "$LINUX"
	cd "$LINUX_DIR"
	make mrproper
	make headers
	find usr/include -type f ! -name '*.h' -delete
	cp -rv usr/include "$BLAZAR"/usr
}
glibc_build() {
	case $(uname -m) in
		i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
		;;
		x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
			ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
		;;
	esac
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
	make && make DESTDIR="$BLAZAR" install
	sed '/RTLDLIST=/s@/usr@@g' -i "$BLAZAR"/usr/bin/ldd


	echo 'int main(){}' | $LFS_TGT-gcc -xc -
	result=$(readelf -l a.out | grep ld-linux)
	
	if [ "${result:-}" = "[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]" ]; then
		echo "glibc готов!"
	elif 
		echo "чтото пошло не так!"
		exit 1 
	fi
	rm -v a.out
}
libstdc_pp_build() {
	cd "$GCC_DIR"
	pre_build

		../libstdc++-v3/configure           \
    		--host=$LFS_TGT                 \
    		--build=$(../config.guess)      \
    		--prefix=/usr                   \
    		--disable-multilib              \
    		--disable-nls                   \
    		--disable-libstdcxx-pch         \
    		--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
	make && make DESTDIR="$BLAZAR" install
	rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
}

main() {
	binutils_build
	gcc_build
	linux_api_buid
	glibc_build
	libstdc_pp_build
	echo "Тулчейн собран!"
}
