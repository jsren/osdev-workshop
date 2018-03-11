---
title: "Control Flow"
permalink: /x86-assembly/control-flow
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

[Registers and Arithmetic](/x86-assembly/registers-arithmetic) covered performing basic
operations on data in registers, memory and immediate values. These allow us to express
simple expressions such as `a + b` in assembly.

This section will cover how to write constructs like `if` statements, `for` loops and
to create and call functions in assembly.

## Labels

Labels are names which we give to particular lines of assembly. These names allow us to
refer to locations within our assembly code, both instructions and data.

The assembly syntax for labels is the name of the label followed by a colon, e.g. `my_label:`.
Labels follow the same rules for naming as for functions in C or Java.


#### Example 1: Using data and code labels

```nasm
my_var: dd 3           ; <- this is a data label

main:                  ; <- this is a code label
    mov eax, [my_var]  ; Loads 3 into eax
add3:                  ; <- this is another code label
    add eax, 3
```

Note that labels do not automatically create functions. They do not alter the assembly
in any way - they just point to particular lines. As a result, were Example 1 to be executed,
the instruction at `main` would run, and then the next instruction would be the one at `add3`.

## Jumping

### Unconditional Jumps

Using code labels allows us to create constructs like loops. The **`jmp`** instruction in x86 allows us
to set the next instruction ("jump") to a particular label.

#### Example 2: Add 3 forever

```nasm
main:
    add eax, 3
    jmp main
```

Example 2 shows some code which will execute in a loop, running `add eax, 3` and then
jumping back to `main` and running `add eax, 3` again. The same assembly could be written in C as:

```c
    while (1) {
        eax += 3;
    }
```

### Conditional Jumps

If we don't want our loops to be infinite, we can add a condition to the jump. To do this, first we
perform a comparison between two values using the **`cmp`** instruction. Then we use one of the variants
of the `jmp` instruction to decide whether to jump or not.

If a jump is not performed, the processor just executes the instruction on the next line.

| Instruction | Description |
| ----------- | ----------- |
| `jmp` | Always jumps |
| `je` | Jumps if the comparison was equal |
| `jne` | Jumps if the comparison was not equal |
| `jz` | Jumps if the value was zero |
| `jnz` | Jumps if the value was not zero |
| `jl` | Jumps if less than |
| `jg` | Jumps if greater than |
| `jle` | Jumps if less than or equal |
| `jge` | Jumps if greater than or equal |

#### Example 3: Add 3 while less than 30 in assembly and C

```nasm
main:
    add eax, 3
    cmp eax, 30
    jl main
    sub eax, 10
```

```c
    while (eax < 30) {
        eax += 3;
    }
    eax -= 10;
```

## Functions

