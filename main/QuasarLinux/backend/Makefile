CXX = g++
CXXFLAGS = -Wall

BASEPACK = basepack/main.cpp \
          basepack/openrc_system.cpp \
          basepack/systemd_system.cpp \
          basepack/zram.cpp
BOOTLOADER = bootloader/efistub.cpp  \
	  bootloader/grub.cpp  \
	  bootloader/main.cpp  \
	  bootloader/otherBoot.cpp  \
	  bootloader/Setbootloader.hpp  \
	  bootloader/syslinux.cpp

USERCFG = userscfg/CloudToUser.cpp \
	  userscfg/CreateUser.cpp \
	  userscfg/main.cpp
PARTMANAGER = parmanager/main.cpp \
	  partmanager/FreeBSDToLinux.cpp \
	  partmanager/Linux2Linux.cpp \
	  partmanager/partmanual.cpp \
	  partmanager/WindowsToLinux.cpp
REGION = region/main.cpp \
	  region/mirrorset.cpp \
	  region/region.cpp


all:
	$(CXX) $(BASEPACK) $(CXXFLAGS) -o basepack.o
	$(CXX) $(BOOTLOADER) $(CXXFLAGS) -o bootloader.o
	$(CXX) $(USERCFG) $(CXXFLAGS) -o userscfg.o
	$(CXX) $(PARTMANAGER) $(CXXFLAGS) -o partmanager.o
	$(CXX) $(REGION) $(CXXFLAGS) -o region.o

install:
	BINARIES = bootloader.o userscfg.o partmanager.o region.o basepack.o
	cp $(BINARIES) build/

clean:
	rm -f $(TARGET)

.PHONY: all clean
