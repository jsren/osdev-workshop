---
title: "Registers and Arithmetic"
permalink: /x86-assembly/registers-arithmetic
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## What is a Register?

A register is a small but very fast store of memory within a processor.
Processors use registers to store results of calculations and processor instructions
typically operate on registers.

## Available Registers

There are three primary types of registers in x86:

- General-purpose registers
- Pointer registers
- Control registers

### General-Purpose Registers

The general-purpose registers are registers which you can use in your assembly
code to store whatever data you wish.

General-purpose registers in x86 have names which are made up of three parts:

1. The width (size) of the register - either **`E`** (32 bits) or nothing (16 bits)
1. The name of the register - **`A`, `B`, `C`, `D`**
1. A letter indicating which byte within the register - **`L`** ("Low", byte 0), **`H`** ("High", byte 1) **`X`** (all bytes)

Example:

| Register | Description |
| -------- | ----------- |
| `EAX` | Access all 32-bits of register A |
| `BX` | Access only 16-bits of register B |
| `CL` | Access byte 0 of register C (8 bits) |
| `DH` | Access byte 1 of register D (8 bits) |

Register names can be written in either lower-case or upper-case.
Only registers whose names end in **`X`** can use the byte selectors **`L`** and **`H`**.

The `eax`/`ax` register is used to store the return value from functions.
This is explained in more detail in the next section.

In addition to these registers there are also the `esi`/`si` and `edi`/`di` registers.
They are general purpose but can also have a special function when used with certain instructions.

The following list contains all of the general-purpose registers in x86: \
`EAX`, `EBX`, `ECX`, `EDX`, `EDI`, `ESI`

### Pointer Registers

The pointer registers are used by the processor to keep track of addresses
during execution.

| Register | Description |
| -------- | ----------- |
| `eip`/`ip` | Address of the next instruction to be executed |
| `esp`/`sp` | Address of the end of the current stack frame |
| `ebp`/`bp` | Address of the start of the current stack frame |

The `eip`/`ip` register is read-only and cannot be directly written to.

These registers will normally be changed automatically by
the processor and you shouldn't use them to store data. We will explain
in detail what these registers are used for in the next sections.

In addition to these registers are the segment registers. We will discuss their
function in [Segmentation 1](/x86-assembly/segmentation1).

### Control Registers

Control registers are registers used to control the processor. Writing to these registers
usually changes the way the processor behaves. As a result, you must have special permissions
to access these and will only be able to do that from your kernel.

We will use the control registers later in the workshop.

## Arithmetic Instructions

With somewhere to store values, we can now perform arithmetic operations on them.

x86 supports all of the basic arithmetic and logical operations, such as addition, subtraction,
multiplication, division, ORing, ANDing, etc.

| Instruction | Description |
| ----------- | ----------- |
| `sub` | Subtracts two values |
| `add` | Adds two values together |
| `div` | Divides two values |
| `mul` | Multiplies two values |
| `mod` | Computes the modulo of two values |
| `or` | Performs a bitwise OR of two values |
| `and` | Performs a bitwise AND of two values |
| `xor` | Performs a bitwise XOR of two values |
| `not` | Performs a bitwise inversion of a value |
| `shl` | Performs a logical left shift |
| `shr` | Performs a logical right shift |
| `inc` | Adds 1 to a value |
| `dec` | Subtracts 1 from a value |
| `mov` | Loads a value into a register |

Each instruction takes one or two parameters. Commonly the first parameter is a register (the _destination operand_)
and the other is either a register or what we call an _immediate value_ (the _source operand_). An immediate value is just a hard-coded number, character or address.

As a result, an assembly instruction such as `add eax, 3` if written in C/Java effectively performs `eax += 3`.

`mov` is a particularly useful instruction which allows us to copy a value from one register to another,
to load the value at a particular memory address into a register or to load an immediate value into a register.

## Accessing Memory



### Examples

#### Adding 3 to the value stored in `eax`:

```asm
ADD eax, 3
```

#### Performing _2x<sup>2</sup>_ on the value stored in `eax`:
```asm
MUL eax, eax
MUL eax, 2
```

#### Adding one to the value stored in `edx`:
```asm
INC edx
```

#### Performing 1024 * 5 and storing the result in `eax`:
```asm
MOV ebx, 1024
MUL ebx, 5
MOV eax, ebx
```

or we can do the same thing using just one register:

```asm
MOV eax, 1024
MUL eax, 5
```

#### Zeroes the 3rd byte in `edi`:
```asm
MOV eax, 255
SHL eax, 16
NOT eax
AND edi, eax
```

#### Loads the value at address `0x7C00` into `eax`:
```asm
MOV eax, dword ptr [0x7C00]
```

## Exercises

To complete these exercises you should use an assembler. In this workshop, we're using `nasm`.

### Exercise 1

Write assembly to add two numbers together.

### Exercise 2

### Exercise 3

### Exercise 4

