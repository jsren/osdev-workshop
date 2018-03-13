---
title: "Segmentation 1"
permalink: /x86-assembly/segmentation1
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

There are two variants of segmentation in x86. This page will focus on the original, real-mode
kind. For segmentation in Protected Mode and the GDT, see [Segmentation 2](/protected-mode/segmentation2).

## Processor Modes

x86 has a long history, and Intel has famously done its best to ensure backwards
compatability, including with its earliest 16-bit processors.

As a result, even modern x86 processors start up in a 16-bit mode called _Real Mode_.
In real mode the processor emulates the earliest models, including many of their
limitations.

The processor's normal 32-bit mode of execution is known as _Protected Mode_. We will
cover Protected Mode, how to enter it and segmentation later in the workshop.
{: .notice-info}

## History

Segmentation was originally designed to allow access to memory beyond 64 kilobytes.
Intel's original processors were 16-bit, meaning that addresses were 16-bit numbers,
leading to this 64KiB limit. However, memory could accept addresses up to 20 bits.

The solution to this was segmentation, where addresses in instructions would be made up of
two parts: a segment address and address offset. The address that we normally use in the
instruction becomes the offset, which is combined with the segment address to give the final
_linear address_.

#### Example 1: Segment Addressing
```nasm
mov eax, [DS:0x7C00]  ; DS is segment register containing segment address
                      ; 0x7C00 is offset
```

Segment registers store the segment addresses. To get the final (linear) address,
the value in the segment register is shifted left by 4 (multiplied by 16)
and then added to the address offset you specify.

#### Example 2: Base-Offset Calculation
```nasm
mov DS, 0x100        ; DS = 0x100
mov eax, [DS:0x7C00] ; eax = [(0x100 << 4) + 0x7C00] = [0x1000 + 0x7C00] = [0x8000]
```

Each memory access in x86 uses an implicit (automatic) segment register. So when you
use `[0x7C00]`, the processor automatically inserts the default segment register `DS`,
becoming `[DS:0x7C00]`.

Segments aren't limited to data addresses. `jmp` and `call` instructions automatically
use the code segment `CS` and `push` and `pop`, use the stack segment `SS`.

| Register | Description |
| -------- | ----------- |
| `CS` | Code Segment Register |
| `DS` | Data Segment Register |
| `SS` | Stack Segment Register |
| `FS` | General-Purpose Segment Register |
| `GS` | General-Purpose Segment Register |

#### Example 2: Default Segment Registers
```nasm
mov eax, [0x7C00]  ; Same as [DS:0x7C00]
jmp 0x7C00         ; Same as CS:0x7C00
mov eax, [ebp + 8] ; Same as [SS:ebp + 8]
```

**If you don't want to use segmentation, just set the segment registers to zero.**

Since the segment bases are shifted left by 4, in real mode this makes addresses 20 bits instead of 16.
This is how Intel allowed programmers to access that larger memory that IBM added. With 20 bits,
you get up to 1 Megabyte!

#### Example 3: Exceeding 16-bit addresses

```nasm
mov DS, 0x1000
mov eax, [DS:0x7C00] ; eax = [0x17C00], a 20-bit address!
```

## Far-Calls & Changing the Segment Registers

All segment registers can be assigned to with the `mov` instruction except for **`CS`**.
In order to change `CS`, you must do what is known as a far-call or long-jump.

Far-calls are the same as regular calls except that you explicitly prefix the address
with either `CS` or a new value for `CS`.

The far-call or long-jump will set the `CS` to whatever prefix you used and then call/jump,
using that `CS` to the address given.

#### Example 4: Setting the CS

```nasm
jmp CS:0x7C00     ; long-jump, use existing CS
jmp 0x100:0x7C00  ; long-jump, change CS to 0x100

; CS is now 0x100

call CS:0x7C00    ; far-call, use existing CS
call 0:0x7C00     ; far-call, change CS to 0

; CS is now 0
```

We will use a far-call when entering Protected Mode.
{: .notice-info}


## The A20 Line

As memory became larger, Intel moved to 32-bit addressing. This created a new problem.
You can use segmentation in 16-bit processors to create addresses wider than 20 bits.
E.g. `[0xFFFF:0xFFFF]` is actually `[0x10FFEF]`, which is **21** bits.

Intel's default behaviour was to ignore the 21st bit, so `[0x10FFEF]` became `[0x0FFEF]`.
However, with 32-bit addresses, this wrapping would no longer happen, as `0x10FFEF` is a
valid 32-bit address.

The wires (lines) connecting the processor to the memory were designated
`A` for address and then their index, so `A0` is the first address line.
{: .notice-info}

Some programs relied on the processor to ignore the 21st bit so 32-bit processors broke
backwards-compatability with the 20-bit addressing. To solve this, IBM added
the _A20 Gate_. This was a boolean flag which enabled or disabled the 21st address line.

If the A20 Gate is false, then the 21st address line is always zero. The A20 Gate was set
to false by default, and so the 21st bit was ignored, emulating Intel's 20-bit addressing.

As we are targeting 32-bit processors, we must change the A20 Gate to true, to enable
the 21st address bit, otherwise all addresses which use this bit will be handled incorrectly.

In typical IBM-style they added this flag to the most suitable location -
the keyboard controller. Thus we need to interface with the keyboard controller to enable
the A20 line. We will cover this later in [Entering Protected Mode](/protected-mode/entering-protected-mode).
