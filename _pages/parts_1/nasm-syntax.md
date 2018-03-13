---
title: "NASM Syntax"
permalink: /x86-assembly/nasm-syntax
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Basics

[Registers and Arithmetic](/x86-assembly/registers-arithmetic) and [Control Flow](/x86-assembly/control-flow)
have already covered most of the basic NASM syntax. Here we will cover much of the rest.

- Literals, such as numbers, can be expressed in hexadecimal via the `h` suffix or `0x` prefix
- Binary literals are suffixed with `b` and can be made more readable by splitting them with `_`
- Character literals can use either single or double quotes (e.g. `'a'`, `"a"`)
- Memory is accessed via addresses in square brackets (`[` and `]`) plus a width specifier (`byte`, `word`, `dword`)

#### Example 1: Basic Syntax
```nasm
label:
    add eax, 2
    add eax, 2h
    add eax, 0x2
    sub eax, 1101b
    div 0011_0001b
    mov ax, word [32]
    cmp ax, 'h'
    jne error
    ret
```

## Storing Data

Registers and the stack can be used to store temporary data. However, data which persists requires global variables. To declare non-temporary data in NASM, we use the `db`, `dw`, `dd` and `dq` commands.

| Command | Description |
| ------- | ----------- |
| `db` | Reserve a byte |
| `dw` | Reserve a word (2 bytes) |
| `dd` | Reserve a double-world (4 bytes) |
| `dq` | Reserve a quad-word (8 bytes) |

These are not processor instructions, but are used by NASM to reserve space in the binary. We can combine these with labels to
create global variables.

```nasm
my_int: dd
```

We can also initialise reserved data by putting an initial value next to the command:

```nasm
my_int: dd 0xDEADBEEF
```

### Strings

Strings can be declared and initialised by using string literals. Notice that in the example we use the `db` command, and that the string ends with a null character `\0` to signify the end.

```nasm
message: db "Hello World!\0"
```

### Structs

Complex data structrures can be created by chaining multiple data commands:

```nasm
my_structure:
    db 4
    dw 0
    dd 0xC0FFEE
```

## Binary Sections

Executables (including the binaries we build for our bootloader/OS) are broken up into sections. Each section contains different types of data. The two most important sections are the `.text` and `.data` sections. The `.text` section is read-only and executable and contains code. The `.data` section is readable and writable but not executable, and contains data.

Our assembly code will mix both data and code, and, unlike with normal programming languages, we must specify in which section
each line of assembly should go.

Before assembly instructions add `section .text`, and before data add `section .data`.

#### Example 2: Code and Data Sections

```nasm
section .text ; make sure in code section

foo:
    mov [my_data], 'a'
    mov [my_data + 1], 'b'
    mov [my_data + 2], 'c'
    mov [my_data + 3], '\0'

section .data  ; switch to data section

my_data:
    dd
    dd
```

For our OS, as nothing actually loads our binary, the write/execute protections which `.text` and
`.data` normally provide will not be enforced. However, this split of code and data improves performance
and makes hard-to-find bugs less likely, so we will still separate them. Additionally, one way in which
you could improve your OS would be to use segmentation or paging to achieve the protection yourself.
{: .notice--info}

## Exporting and Importing Symbols

In order to share functions and variables between our assembly and C code, we need to import and
export their names.

#### Example 3: A valid C program printing a string with printf

```nasm
section .data
format: db "%d\0"   ; declare format string

section .code
extern printf       ; import 'printf'

global main         ; export 'main'
main:
    enter

    push 42
    push format
    call printf

    leave
    ret
```

Importing external functions/variables is done with the `extern` keyword followed by the name (symbol).

Equally, exporting functions/variables to other code is done with the `global` keyword followed by the name.

## Instruction Width

x86 uses 32-bit instructions. However, when the processor first starts it is in _real mode_, and so
for historic reasons, we need to limit the instructions to be 16-bit.

We can switch between 16- and 32-bit instruction sets with the `bits 16` and `bits 32` commands.

#### Example 4: Using Both 16-bit and 32-bit Code

```nasm
bits 16         ; Switch to 16-bit code

start:
    ; Set up protected mode here
    ; ...

    jmp cs:main ; Far-jump into 32-bit code


bits 32         ; Switch to 32-bit code
main:
    ; now in 32-bit code
```

The designation '32-bit' here refers to the maximum instruction width of 4 bytes;
not all instructions in x86 are 4 bytes wide.
{: .notice--info}

## Macros

NASM has support for macros, which you may wish to use to achieve more complex things (e.g. defining data structures).

While we won't cover these in the workshop, we will mention the `%include` macro which allows you to include one assembly
code file in another.

```nasm
%include "other-file.asm"
```
