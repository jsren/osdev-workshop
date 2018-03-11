#!/usr/bin/make -f 
# -----------------------------------------------
# install.mk - (c) 2018 James Renwick
#
# Downloads and cross-compiles GCC and binutils
# Installs into /usr/os-workshop-gcc

# The install directory (do not change!)
export PREFIX ?= /usr/os-workshop-gcc
# The target architecture
export TARGET ?= i686-elf
# The version of GCC to build
export TARGET_GCC ?= gcc-7.3.0
# The version of binutils to build
export TARGET_BINUTILS ?= binutils-2.30

export PATH := $(PREFIX)/bin:$(PATH)
SRC_APT := g++ bison flex libgmp3-dev libmpfr-dev libmpc-dev texinfo

.PHONY: bootstrap setup build-all gcc binutils clean-all clean-binutils clean-gcc uninstall

bootstrap:
	sudo apt install $(SRC_APT)
	mkdir -p build
	cd build && $(MAKE) -j 2 -f $(abspath $(CURDIR)/install.mk) build-all

setup:
	sudo mkdir -p $(PREFIX)
	sudo chmod -R a+rwx /usr/os-workshop-gcc/

$(TARGET_GCC).tar.gz:
	wget ftp://ftp.gnu.org/gnu/gcc/$(TARGET_GCC)/$(TARGET_GCC).tar.gz

$(TARGET_BINUTILS).tar.gz:
	wget ftp://ftp.gnu.org/gnu/binutils/$(TARGET_BINUTILS).tar.gz

$(TARGET_GCC)/README: $(TARGET_GCC).tar.gz
	tar -xzf $(TARGET_GCC).tar.gz

$(TARGET_BINUTILS)/README: $(TARGET_BINUTILS).tar.gz
	tar -xzf $(TARGET_BINUTILS).tar.gz

build-binutils/Makefile: $(TARGET_BINUTILS)/README
	mkdir -p build-binutils
	cd build-binutils && ../$(TARGET_BINUTILS)/configure --target=$(TARGET) --prefix="$(PREFIX)" --with-sysroot --disable-nls --disable-werror

$(PREFIX)/bin/$(TARGET)-as: build-binutils/Makefile
	cd build-binutils && $(MAKE)
	cd build-binutils && $(MAKE) install

build-gcc/Makefile: $(PREFIX)/bin/$(TARGET)-as $(TARGET_GCC)/README
	mkdir build-gcc
	cd build-gcc && ../$(TARGET_GCC)/configure --target=$(TARGET) --prefix="$(PREFIX)" --disable-nls --enable-languages=c,c++ --without-headers

$(PREFIX)/bin/$(TARGET)-gcc: build-gcc/Makefile
	which -- $(TARGET)-as || { echo "Target binutils not in path" && exit 1; }
	cd build-gcc && $(MAKE) all-gcc
	cd build-gcc && $(MAKE) all-target-libgcc
	cd build-gcc && $(MAKE) install-gcc
	cd build-gcc && $(MAKE) install-target-libgcc

binutils: setup $(PREFIX)/bin/$(TARGET)-as

gcc: setup $(PREFIX)/bin/$(TARGET)-gcc

clean-binutils:
	rm -rf build/build-binutils
clean-gcc:
	rm -rf build/build-gcc
clean-all:
	rm -rf build

build-all: gcc
	$(TARGET)-gcc --version

	@echo ==== Build Complete ====
	whereis $(TARGET)-gcc

	rm -rf build-binutils build-gcc $(TARGET_BINUTILS) $(TARGET_GCC)

uninstall: clean-all
	sudo rm -rf /usr/os-workshop-gcc/
