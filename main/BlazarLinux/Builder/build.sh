#!/usr/bin/env bash

#############################
##  QuasarBuilder          ##
##  by: QuasarFoks         ##
##  os: BlazarLinux        ##
##  type: main             ##
#############################


export BLAZAR=/mnt/blazar
export TOOL="$BLAZAR"/tool
export SOURCES="$BLAZAR"/sources

start_build() {
	wget --input-file=wget-list-sysv --continue --directory-prefix="$BLAZAR"/sources
	
	
	pushd "$BLAZAR"/sources
  		md5sum -c md5sums
	popd



	mkdir -pv $BLAZAR/{etc,var} $BLAZAR/usr/{bin,lib,sbin}

	for i in bin lib sbin; do
  		ln -sv usr/$i $BLAZAR/$i
	done

	case $(uname -m) in
  		x86_64) 
			ln -sf usr/lib64 $BLAZAR/lib64 
			ln -sf lib "$BLAZAR"/usr/lib64
			;;
	esac

	sudo groupadd buildbot 
	sudo useradd -s /bin/bash -g buildbot -m -k /dev/null buildbot
	passwd buildbot

	chown -v buildbot "$BLAZAR"/{usr{,/*},lib,var,etc,bin,sbin,tools}
	case $(uname -m) in
  		x86_64) chown -v lfs "$BLAZAR"/lib64 ;;
	esac
}
settings_buildbot() {
	cat > /home/buildbot/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

	cat > /home/buildbot/.bashrc << "EOF"
set +h
umask 022
BLAZAR=/mnt/blazar
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j$(nproc)

EOF
	

}


main_start() {
	start_build
	settings_buildbot
	sudo -C buildbot << EOF
source ~/.bash_profile
source ~/.bashrc
EOF

}


cross_build() {
	./build_cross.sh
}

toolchain_build() {
	./build_tool.sh
}

main_build() {
	cp build.sh "$BLAZAR"
	./build.sh
}

main() {
	main_start
	cross_build
	toolchain_build
	main_build

}
