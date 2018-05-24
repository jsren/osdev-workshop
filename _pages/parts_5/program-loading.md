---
title: "Progam Loading"
permalink: /user-programs/program-loading
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Program Header

According to [Wikipedia](https://en.wikipedia.org/wiki/Computer_program), a program is "a collection of instructions that performs a specific task when executed by a computer". For our definition, a program contains many other things. It is the instructions and associated data required to start a process. It is also typically has a set of restrictions on the execution environment (architecture, operating system, etc.) and a list of dependencies (e.g. libraries).

Programs are usually described by a program header - a table giving detailed information about the program's requirements to the operating system.

### The Section Table

Each program is split up into _sections_. Each section groups code/data that share properties. For example, program instructions are stored in the **.text** section, and so data in this section should be allowed to be executed.

Programs can have their own custom sections, but in general most programs have at least the following sections:

| Abbreviation | Name | Description |
| ------------ | ---- | ----------- |
| **.text** | Code Section | Section containing executable instructions |
| **.data** | Data Section | Section containing writable program data |
| **.bss** | Zero Data Section | Section containing program data initialised to zero |
| **.rodata** | Read-only Data Section | Section containing read-only program data |

A program lists its sections in its _section table_, a table containing the details for each section. This table is usually placed after the program header and before the sections themselves.

### The Symbol Table

The symbol table is the 

## Loading a Program

The _program loader_ is the part of the kernel responsible for launching programs. To run a program, the program loader copies the sections required by the program to the requested location within a (new) process' memory space.

The program typically designates some address within the **.text** section as the start address (the entry point, in C/C++ this is the `_start` symbol). Once the sections have been loaded, the program loader should start a new thread at that start address.

When a program is built, the compiler assumes that each section starts at a specific address in memory (RAM). This allows it to use absolute addressing, where it can hard-code the addresses of variables and functions into the assembly. However, as a result, the program loader must load each section into the correct address.

As part of the section table, each section which is to be loaded into memory has a virtual base address, which specifies where in virtual memory to load the section.

Sections can also have access contraints, such as whether they can be executed or written to. These can be enforced via page table entry flags (see [Paging](/the-kernel/paging)). To facilitate this, sections are often page-aligned.

## The ELF Format

## Libraries
