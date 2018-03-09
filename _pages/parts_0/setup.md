---
title: "Install all the things!"
permalink: /workshop-setup/setup
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Linux

### Ubuntu 16/14

1. Run `cd ~/` to change to your home directory
1. Run `sudo apt install wget` to install wget
1. Run `wget [LINK]` to download the pre-built compiler
1. Extract the file with `tar -xjf [FILE]`
1. Run `cd [FILE]` to enter the directory
1. Run `sudo install.sh` to install the compiler
1. Run `source ~/.bashrc` to update your environment
1. Run `sudo apt install nasm` to install the assembler

The compiler (`none-eabi-gcc`) and assembler (`nasm`) should now be
installed.

You can uninstall the compiler and assembler with

1. `sudo install.sh remove`
1. `sudo apt remove nasm`

### Other Linux distributions

1. Run `cd ~/` to change to your home directory
1. Run `sudo apt install wget` to install wget
1. Run `wget [LINK]` to download the cross-compiler script
1. Run `sudo install.sh` to build and install the compiler
1. Read through workshop website, check Facebook etc. until complete
1. Run `source ~/.bashrc` to update your environment
1. Run `sudo apt install nasm` to install the assembler

(If you're interested in what's happening, check out [this](https://wiki.osdev.org/GCC_Cross-Compiler) page.)

The compiler (`none-eabi-gcc`) and assembler (`nasm`) should now be
installed.

You can uninstall the compiler and assembler with

1. `sudo install.sh remove`
1. `sudo apt remove nasm`

## Windows

### Windows 10

Windows 10 supports native Linux binaries via the Windows Subsytem for Linux (WSL).

1. Search for `Windows Powershell` in the start menu, right-click and run as administrator
1. Run `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux`
1. Go to [https://www.microsoft.com/store/productId/9NBLGGH4MSV6](https://www.microsoft.com/store/productId/9NBLGGH4MSV6)
 or open the Microsoft Store and search for and install 'Ubuntu'.

With this installed, you should be able to run `bash` from the command line.

1. Run `bash`
1. Run `cd ~/` to change to your home directory
1. Run `sudo apt install wget` to install wget
1. Run `wget [LINK]` to download the pre-built compiler
1. Extract the file with `tar -xjf [FILE]`
1. Run `cd [FILE]` to enter the directory
1. Run `sudo install.sh` to install the compiler
1. Run `source ~/.bashrc` to update your environment
1. Run `sudo apt install nasm` to install the assembler

The compiler (`none-eabi-gcc`) and assembler (`nasm`) should now be
installed.

You can uninstall the compiler and assembler with

1. `sudo install.sh remove`
1. `sudo apt remove nasm`

### Other Windows Versions

In order to run the compiler, you will require a Linux shell. The easiest to set up is Cygwin.

To install Cygwin:

1. Visit [https://www.cygwin.com/install.html](https://www.cygwin.com/install.html)
   and download either the 64-bit or 32-bit setup
1. Run the setup installer and proceed with setup
1. Make sure "Install from Internet" is selected, click Next
1. Select an installation directory, click Next
1. **Set a valid location for the package directory, e.g. your Downloads folder.**
1. Configure your network access (defaults are normally fine), click Next
1. Select any item from the box and click Next
1. The "Select Packages" page should now be visible
1. Search for "nasm"
1. Expand "Devel" in the tree
1. Click on the "skip" label next to the entry for nasm until it changes to a version number (e.g. `2.10.07`)
1. Search for "wget"
1. Expand "Web" in the tree
1. Click on the "skip" label next to the entry for wget until it changes to a version number (e.g. `1.19.1`)
1. Search for "make"
1. Expand "Devel" in the tree
1. Click on the label next to the entry for make until it changes to a version number (e.g. `4.2.1`)
1. Click Next and Next again to complete installation

With this installed, you should be able to run `bash` from the command line.

1. Run `bash`
1. Run `cd ~/` to change to your home directory
1. Run `wget [LINK]` to download the pre-built compiler
1. Extract the file with `tar -xjf [FILE]`
1. Run `cd [FILE]` to enter the directory
1. Run `sudo install.sh` to install the compiler
1. Run `source ~/.bashrc` to update your environment

The compiler (`none-eabi-gcc`) and assembler (`nasm`) should now be
installed.

## OSx

`brew install qemu`
