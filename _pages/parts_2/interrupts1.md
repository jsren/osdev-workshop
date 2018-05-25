---
title: "Interrupts and the PIC"
permalink: /input-output/interrupts-and-the-pic
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---
# Programmable Interrupt Controller (PIC)

## Introduction

The PIC is a hardware component designed to handle hardware (I/O) interrupts. It has been made obsolete by the Advanced Programmable Interrupt Controller (IOAPIC) which we will cover [later](/drivers/interrupts3). However, not all computers have an IOAPIC, and the PIC is simple to configure and use while your bootloader or operating system is starting.

### IRQ Mapping

So far, we have been using **#INT** to refer to interrupt vectors. To complicate things, the PIC has its own set of interrupt numbers. These correspond to the physical pins to which external devices connect their interrupt lines (wires).

TODO: diagram

PIC interrupt numbers are typically prefixed with **IRQ** (Interrupt ReQuest), to clearly distinguish them from interrupt vectors.

The PIC maintains a table mapping IRQs to interrupt vectors. When an interrupt is triggered on one of the PIC's pins, it looks up the vector in its table and sends that to the processor to be raised.

By default, the PIC maintains the following mapping:

| IRQ | #INT |
| --- | ---- |
| 0x0-0x7 | 0x8-0xF |
| 0x8-0xF | 0x70-0x78 |

This is okay in Real Mode, however in Protected Mode these #INT assignments clash with those for [processor exceptions](/protected-mode/exceptions) (e.g. IRQ0 maps to #INT8, which is a double-fault, **#DF**).

### Master-Slave

The PIC is actually comprised of two identical chips, with one being the "master" and the other the "slave". This is because each chip has only 8 interrupt lines, but the number of required hardware (IO) interrupts increased beyond that, and IBM's solution was to simply attach another PIC.

This decision makes things complicated for us, as we will see later.

## Standard IRQ Assignment

| IRQ | Description |
| --- | ----------- |
| IRQ0 | Programmable Interrupt Timer interrupt |
| IRQ1 | PS/2 port 1 (keyboard) interrupt |
| IRQ2 | _unused_ |
| IRQ3 | COM2/COM4 interrupt |
| IRQ4 | COM1/COM3 interrupt |
| IRQ5 | Sound Card/LPT2 interrupt |
| IRQ6 | Floppy Disk interrupt |
| **IRQ7** | LPT1 interrupt |
| IRQ8 | Real-Time Clock interrupt |
| IRQ9 | _undefined_ |
| IRQ10 | _undefined_ |
| IRQ11 | _undefined_ |
| IRQ12 | PS/2 port 2 (mouse) interrupt |
| IRQ13 | FPU co-processor interrupt (obsolete) |
| IRQ14 | Primary ATA disk interrupt |
| **IRQ15** | Secondary ATA disk interrupt |

IRQ2 is known as the _cascade_ IRQ and is actually used by the slave PIC to signal to the master that it has recieved an interrupt. The master should never trigger this IRQ on the processor.
{: .notice--info}

## Configuring the PIC

The exact sequence and meaning of the PIC configuration commands is beyond the scope of this workshop. However, for more information, the datasheet for the PIC can be found [here](/assets/8259A.pdf).

```c

```

## Handling Interrupts

### End of Interrupt (EOI)

### Simultaneous Interrupts

### Spurious Interrupts

Interrupts are not perfect. Timing errors or noise on interrupt lines can incorrectly trigger interrupts on the PIC.

When this happens, the PIC notifies the processor that an interrupt has occurred, but as the interrupt source is [unreliable](https://wiki.osdev.org/8259_PIC#Spurious_IRQs), it cannot provide a vector. Instead, it will send either IRQ7 (if the interrupt was on the master) or IRQ15 (if on the slave). These are known as spurious interrupts.

In order to check if an interrupt on IRQ7/15 is a real interrupt or a spurious interrupt, first read the Interrupt Status Register - spurious interrupts will not have their bit set in the ISR. If the IRQ is not set in the ISR, then it is spurious and can be ignored.

