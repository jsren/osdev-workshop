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

<img src="/assets/images/parts_0/register_breakdown.svg" alt="Register Breakdown" style="width: 650px;"/>

#### Examples

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
| `div` | Divides two unsigned values |
| `mul` | Multiplies two unsigned values |
| `idiv` | Divides two signed values |
| `imul` | Multiplies two signed values |
| `or` | Performs a bitwise OR of two values |
| `and` | Performs a bitwise AND of two values |
| `xor` | Performs a bitwise XOR of two values |
| `not` | Performs a bitwise inversion of a value |
| `shl` | Performs a logical left shift |
| `shr` | Performs a logical right shift |
| `inc` | Adds 1 to a value |
| `dec` | Subtracts 1 from a value |
| `mov` | Loads a value into a register |

#### Example 1: Add 3 to the value stored in `eax`

```nasm
ADD eax, 3
```

Each instruction takes one or two parameters (a.k.a. _operands_). Commonly the first parameter is a register (the _destination operand_) and the other is either a register or what we call an _immediate value_ (the _source operand_). An immediate value is just a hard-coded number, character or address.

Instructions usually take the one or two parameters, do something with them and store the result in the destination operand.
As a result, an assembly instruction such as `add eax, 3` effectively performs `eax += 3`.

`MOV` ("move") is a particularly useful instruction which allows us to load a value into a register. This value could be an immediate value, a value in another register, or the value at a certain memory address. Note that despite its name, it doesn't move data - it copies data.

#### Example 2: Perform 1024 + 5 with `ebx` and store the result in `eax`
```nasm
MOV ebx, 1024
ADD ebx, 5
MOV eax, ebx
```

## Accessing Memory

So far we've seen loading immediate values (hard-coded numbers etc.) into registers and copying values between registers. However we will often want to load and store values to memory (RAM). This introduces an extra complication - we must now tell the assembler how much data to copy to/from memory.

#### Example 3: Load the value at address `0x7C00` into `eax`
```nasm
mov eax, dword [0x7C00]
```

In assembly we surround memory addresses in square brackets (`[` and `]`), for example `[1024]` represents the **data at** address 1024. We aren't limited to hard-coded addresses - we can also use the value in a register as an address:

#### Example 4: Load the value at address `0x7C00 + 16` into `eax`
```nasm
mov esi, 0x7C00
add esi, 16
mov eax, dword [esi]
```

x86 adds one more trick: we can use some simple expressions when computing addresses:

#### Example 5: Load the value at address `0x7C00 + 16` into `eax`
```nasm
mov eax, dword [0x7C00 + 16]
```

### Specifying Size

As was mentioned previously, in order to access memory in assembly we must tell the assembler the size of the memory we wish to access. In NASM that is achieved simply by putting `byte` (1 bytes), `word` (2 bytes), or `dword` (3 bytes) before the square brackets:

#### Example 6: Load the value at address `0x7C00 + 16` into `eax`
```nasm
mov al,  byte  [0x7C00]
mov ax,  word  [0x7C00]
mov eax, dword [0x7C00]
```

## Notes on Assembly Syntax

All variants of x86 assembly language follow one of two styles: AT&T syntax or Intel syntax.
So far we have been using Intel-syntax assembly. AT&T syntax swaps the source and destination parameters,
often requires giving explicit sizes to instructions, and adds special symbols to indicate registers (`%`) and
immediate values (`$`). For example, `mov eax, 3` in Intel syntax becomes `movl $3, %eax` in AT&T syntax.

As AT&T syntax is commonly seen to be much less readable (by humans!), we will only be using Intel syntax in this workshop.

GAS (the GNU assembler) and objdump and other GNU tools use AT&T-syntax assembly, although you can usually set a command-line option to use Intel syntax instead.

## Examples

### Comments

```nasm
NOP ; The NOP instruction does nothing.
```

### Adding 1 to the value stored in `edx`

```nasm
INC edx
```

### Performing 1024 * 5 and storing the result in `eax`

Division and multiplication are special in x86 (for historic reasons) and they always use `EAX`
as the destination operand. This means that they use `EAX` as an automatic first argument
and the result will be stored in `EAX`. _The `EDX` register will also be modified._

```nasm
MOV eax, 1024
MOV ebx, 5
MUL ebx
```

### Performing 1024 / 5 and storing the result in `eax`

See the previous example for details on how division works.
**The `EDX` register will contain the remainder.**

```nasm
MOV eax, 1024
MOV ebx, 5
DIV ebx
```

### Zeroing the 3rd byte in `edi`

```nasm
MOV eax, 255
SHL eax, 16
NOT eax
AND edi, eax
```

### Loading the value at address `0x7C00` into `eax`

```nasm
MOV eax, dword [0x7C00]
```

## Exercises

To complete these exercises you should use an assembler. In this workshop, we're using `nasm`. To get started, clone [this repo](https://github.com/jsren/os-workshop-ex1). For each exercise create a new file ending with `.asm`.

1. Run `bash`
1. Clone the exercise repository (`git clone https://github.com/jsren/os-workshop-ex1`)
1. `cd` into the os-workshop-ex1 directory
1. Create a new file for your code
1. Write your code
1. If you wish to print a number, make sure the value is in `EAX` and add the instruction `call print_number`
1. If you wish to print a string, make sure the address of the string is in `EAX` and the length of the string is in `EBX` and add the instruction `call print_string`
1. Run `nasm -p utils.asm -f elf <your filename> -o <output>`

### Example

number.asm

```nasm
mov eax, 3
call print_number
```

string.asm

```nasm
my_string: db "Hello World"

mov eax, my_string
mov ebx, 11
call print_number
```

#### Assembling and running

```bash
$ nasm -p utils.asm number.asm -o number
$ ./number
3
$
```

### Exercise 1

Write assembly to add two numbers together.

### Exercise 2

### Exercise 3

### Exercise 4
