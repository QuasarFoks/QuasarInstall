CXX = g++
CXXFLAGS = -Wall -Wextra -std=c++20 -g
LDFLAGS = -lcurl -lncurses #lintl


SRCDIR = main/QuasarLinux/REV/modules
BUILDDIR = build

TARGET = $(BUILDDIR)

# Найти все .cpp файлы

all:
	g++ $(SRCDIR)/basepack.cpp -o basepack -lcurl -lncurses
	g++ $(SRCDIR)/boot_install.cpp -o bootloader -lcurl -lncurses

install:
	mkdir $(BUILDDIR)
	cp $(SRCDIR)/basepack $(BUILDDIR)
	cp $(SRCDIR)/bootloader $(BUILDDIR)
# Очистка
clean:
	rm -rf $(BUILDDIR)

# Запуск
run: $(TARGET)
	./$(TARGET)

.PHONY: clean run
