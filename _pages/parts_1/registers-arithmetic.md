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
Processor instructions typically operate on registers, and processors use
registers to store the results of calculations.

## General-Purpose Registers

The general-purpose registers are registers which you can use in your assembly
code to store whatever data you wish.

x86 has six general-purpose registers: `EAX`, `EBX`, `ECX`, `EDX`, `EDI`, `ESI`.

### Register Naming

Register names are case-insensitive - they can be written in either lower-case or upper-case.
Each register is 32 bits (4 bytes) wide. x86 uses the prefix `E` to indicate this.

If the register name is given without the `E` (e.g. `AX`, `SI`), only the lower 16 bits of the register are accessed.
For registers whose name ends in an `X`, bytes 0 and 1 can be accessed individually by replacing the `X`
with the suffix **`L`** ("Low", byte 0) or **`H`** ("High", byte 1).

You cannot combine the `E` prefix with an `L` or `H` suffix (e.g. `EAH` is not valid).

Example:

| Register | Description |
| -------- | ----------- |
| `EAX` | Access all 32-bits of register A |
| `BX` | Access only 16-bits of register B |
| `CL` | Access byte 0 of register C (8 bits) |
| `DH` | Access byte 1 of register D (8 bits) |
| `SI` | Access only 16-bits of register `ESI` |
| `EDI` | Access all 32-bits of register `EDI` |


## Arithmetic Instructions

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

#### Example 1: adding 3 to the value stored in `eax`:

```asm
ADD eax, 3
```

Each instruction takes one or two parameters (a.k.a. _operands_). Commonly the first parameter is a register (the _destination operand_) and the other is either a register or what we call an _immediate value_ (the _source operand_). An immediate value is just a hard-coded number, character or address.

Instructions usually take the one or two parameters, do something with them and store the result in the destination operand.
As a result, an assembly instruction such as `add eax, 3` effectively performs `eax += 3`.

#### Example 2: performing _2x<sup>2</sup>_ on the value stored in `eax`:
```asm
MUL eax, eax
MUL eax, 2
```

`MOV` ("move") is a particularly useful instruction which allows us to load a value into a register. This value could be an immediate value, a value in another register, or the value at a certain memory address.

#### Example 3: performing 1024 * 5 with `ebx` and storing the result in `eax`:
```asm
MOV ebx, 1024
MUL ebx, 5
MOV eax, ebx
```

## Accessing Memory

## Notes on Assembly Syntax

All variants of x86 assembly language follow one of two styles: AT&T syntax or Intel syntax.
So far we have been using Intel-syntax assembly. AT&T syntax swaps the source and destination parameters,
often requires giving explicit sizes to instructions, and adds special symbols to indicate registers (`%`) and
immediate values (`$`). For example, `mov eax, 3` in Intel syntax becomes `movl $3, %eax` in AT&T syntax.

As AT&T syntax is commonly seen to be much less readable (by humans!), we will only be using Intel syntax in this workshop.

GAS (the GNU assembler) and objdump and other GNU tools use AT&T-syntax assembly, although you can usually set a command-line option to use Intel syntax instead.

## Examples

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

