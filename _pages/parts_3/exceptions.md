---
title: "Exceptions"
permalink: /protected-mode/exceptions
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

Exceptions are a type of interrupt raised by the processor, generally in response to some error condition.

## Interrupts

As a refresher, interrupts are external signals sent to the processor which cause it to stop whatever
its currently doing and switch to a function which the kernel has registered to handle that particular signal.

Interrupt handlers (what we call Interrupt Service Routines - ISRs) should complete as quickly as possible. Once
they return, the processor resumes whatever it was previously doing.

## Available Exceptions

The table below lists the exceptions defined in x86. Exceptions which are more commonly encountered are highlighted in bold.

| Abbrev. | Vector / Number | Name | Cause |
| ------- | --------------- | ---- | ----------- |
| **#DE** | 0x00 | **Divide-by-Zero Error** | An instruction attempting to divide by zero |
| #DB | 0x01 | Debug | A debug event (read/write breakpoint, single-step etc.) |
| - | 0x02 | Non-Maskable Interrupt | A critical external hardware interrupt |
| #BP | 0x03 | Breakpoint | Hitting a hardware breakpoint |
| #OF | 0x04 | Overflow | `div` or `into` instructions overflowing |
| #BR | 0x05 | Bound Range Exceeded |  `bound` instruction check failing |
| **#UD** | 0x06 | **Invalid Opcode** | Trying to execute an unknown or invalid instruction |
| #NM | 0x07 | Device not Available | Trying to use floating-point instructions with the FPU disabled |
| **#DF** | 0x08 | **Double Fault** | An exception being raised within an interrupt handler |
| #TS | 0x0A | Invalid TSS | An invalid segment selector in the TSS |
| #NP | 0x0B | Segment not Present | Loading a not-present segment (except for SS) |
| #SS | 0x0C | Stack Segment Fault | Exceeding or loading a not-present stack segment |
| **#GP** | 0x0D | **General Protection Fault** | Access check failed (write to read-only segment, privileged instruction in ring 3, etc.) |
| **#PF** | 0x0E | **Page Fault** | Page directory/table entry missing or access/presence check failed |
| #MF | 0x10 | x87 Floating-Point | `fwait` or `wait` instruction during a numeric error state |
| #AC | 0x11 | Alignment Check | When alignment checking is enabled and a misaligned access occurs in ring 3 |
| #MC | 0x12 | Machine Check | Internal processor/cache/bus error |
| #X[MF] | 0x13 | SIMD Floating Point Exception | Floating-point math error with SIMD instruction |
| #VE | 0x14 | Virtualization Exception | Extended Page Table (EPT) violation |
| #SX | 0x1E | Security Exception | AMD internal exception |

## Triple-Fault

An exception missing from this table is the Triple Fault. The triple fault does not cause a handler to run
but instead causes a hard-reset of the processor. This will immediately restart your computer.

Similar to the double fault, which occurs when an exception is raised during an interrupt handler, a triple fault is triggered when an exception is raised within the double-fault handler.

## Handling Exceptions

As exceptions are a type of interrupt, their handlers are registered in the Interrupt Descriptor Table (Descriptor).

However, unlike standard interrupts, the **#DF**, **#TS**, **#NP**, **#SS**, **#GP**, **#PF**, **#AC** and **#SX** exceptions have a 32-bit error code which must be popped from the stack during the handler.

#### Example: ISR for a Page Fault Exception

```nasm
handle_pagefault:
    pushad
    pop eax    ; pop error code

    ; ... handle page fault ...

    popad
    iret       ; return to faulting instruction
```
