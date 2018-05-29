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

<img src="/assets/images/parts_2/pic.svg" />

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

The IRQs in bold are known as the [spurious interrupts](#spurious-interrupts), and may require special treatment.
{: notice--info}

## Communicating with the PIC

The master and slave PIC each use two different I/O [ports](/input-output/ports-and-memory-mapping) for communication.

| Port | Description | Access |
| ---- | ----------- | ------- |
| 0x20 | Master PIC Command Port | Write-only |
| 0x21 | Master PIC Data Port | Read-only |
| 0x21 | Master PIC IRQ Mask Port | Write-only |
| 0xA0 | Slave PIC Command Port | Write-only |
| 0xA1 | Slave PIC Data Port | Read-only |
| 0xA1 | Slave PIC IRQ Mask Port | Write-only |

You may notice that ports 0x21 and 0xA1 show up twice in the table - that is because they have different functions depending on whether you read (`inb`) or write (`outb`) to them.
{: .notice--info}

## Configuring the PIC

Before we can use the PIC, we must correctly configure it. In particular, we should re-map the tables so that the IRQs no longer conflict with the Protected Mode exception interrupt vectors.

Recall that by default, the master PIC [maps IRQs](#irq-mapping) 0x0-0x7 to vectors 0x8-0xF. It is common to change this mapping such that the IRQs map instead to vectors 0x20-0x27, just after the range of Intel's exception #INT vectors (0x0 - 0x1F).

We can do a similar thing for the slave PIC. Here, we chosen to map its IRQs immediately after the master's (i.e. 0x28-0x2F).

We have provided example code for initialising the PIC in this way:

```c
// Begin initialisation
asm_outb(0x20, 0x11);
asm_outb(0xA0, 0x11);

// Set #INT vector offset for master IRQs
asm_outb(0x21, 0x20);
// Set #INT vector offset for slave IRQs
asm_outb(0xA1, 0x28);

// Establish master-slave relationship
asm_outb(0x21, 0x4);
asm_outb(0xA1, 0x2);

// Set operating mode (8086)
asm_outb(0x21, 0x1);
asm_outb(0xA1, 0x1);
```

The exact sequence and meaning of the PIC configuration commands is beyond the scope of this workshop. However, for more information, the datasheet for the PIC can be found [here](/assets/8259A.pdf).

The example initialisation code given at [wiki.osdev.org](https://wiki.osdev.org/PIC#Initialisation) uses unnecessary calls to a delay function `io_wait`. These are only _possibly_ useful for very, very old processors.
{: .notice--info}

### Enabling/Disabling (Masking) Interrupts

Each PIC (master and slave) maintains a set of 8 bits, one for each IRQ, where each bit determines wither the corresponding IRQ is disabled.

For example, on the master, the first bit represents IRQ0, the second IRQ2, and so on. And on the slave, the first bit represents IRQ8, the second IRQ9 etc.

Importantly, if IRQ2 is disabled on the master PIC, all of the IRQs on the slave PIC (IRQ8-IRQ15) will also be disabled. Thus, **for any of the slave IRQs to be enabled, IRQ2 must be enabled on the master**.

For example, to only enable IRQs 0, 4 and 8 (disable IRQ 1, 3, 5-7, 9-15):

```c
    // Enable only IRQs 0, 2 and 4 on master
    asm_outb(0x21, 0b11101010);
    // Disable all but IRQ 8 on slave
    asm_outb(0xA1, 0b11111110);
```

To disable the PIC entirely (for example, when using the APIC instead), simply set all of the bits (0xFF) to disable all IRQs.

## Handling Interrupts

### End of Interrupt (EOI)

As the PIC is independent of the CPU, it has no way of knowing when the CPU has finished handling an interrupt.

Thus, we must manually notify the PIC, in our interrupt handler (ISR), when the interrupt is complete.

To do this, we send an End of Interrupt (EOI) command, byte **0x20**, to the master PIC command port (0x20).

```c
    asm_outb(0x20, 0x20); // Send EOI
```

However, when the interrupt comes from the slave PIC, we must notify both the master and slave that the interrupt is complete:

```c
    asm_outb(0xA0, 0x20); // Send EOI to slave
    asm_outb(0x20, 0x20); // Send EOI to master
```

where the slave is at port **0xA0**.

### Simultaneous Interrupts

It is entirely possible that another interrupt can be triggered while an earlier one is already being handled.

To deal with this, the PIC prioritises interrupts based on their IRQ number: the lower the IRQ, the higher the priority.

It also allows the processor to _preempt_ an executing interrupt handler (ISR), switching mid-ISR to a different ISR with a higher priority.

### Checking Pending Interrupts

Interrupts which have been triggered on the CPU, but not yet marked as complete (via an EOI) are marked as pending in the In-Service Register (ISR).

Each In-Service Register is made up of 8 bits, one bit for each IRQ, to indicate whether the IRQ is pending.

For example, the first bit in the ISR represents IRQ0, the second IRQ2, and so on.

In addition to the ISR, there is also an 8-bit Interrupt Request Register (IRR), which indicates that an IRQ has been triggered, but not yet sent to the CPU.

| Register | Command |
| -------- | ------- |
| IRR | 0x0A |
| ISR | 0x0B |

This are registers contained within both the master and slave PICs. Unlike the processor registers we have seen before, we cannot access these directly (e.g. via `mov`). Instead we will use port IO (`inb` and `outb`) to access them indirectly.

To read from either register, you must first indicate to the PIC which particular register to read by sending the appropriate command byte (as given in the table above) to the Command Register (at port 0x20 for master, 0xA0 for slave).

You can then read the register value for each PIC from the corresponding data port (0x21 for master, 0xA1 for slave):

```c
// Request read from ISR
asm_outb(0x20, 0x0B);
asm_outb(0xA0, 0x0B);

// Read from ISR
uint8_t master_isr = asm_inb(0x21);
uint8_t slave_isr = asm_inb(0xA1);
```

### Spurious Interrupts

Interrupts are not perfect. Timing errors or noise on interrupt lines can incorrectly trigger interrupts on the PIC.

When this happens, the PIC notifies the processor that an interrupt has occurred, but as the interrupt source is [unreliable](https://wiki.osdev.org/8259_PIC#Spurious_IRQs), it cannot provide a vector. Instead, it will send either IRQ7 (if the interrupt was on the master) or IRQ15 (if on the slave). These are known as spurious interrupts.

In order to check if an interrupt on IRQ7/15 is a real interrupt or a spurious interrupt, first read the In-Service Register (ISR) - spurious interrupts will not have their bit set in the ISR. If the IRQ is not set in the ISR, then it is spurious and can be ignored.

**Spurious interrupts must not send an End of Interrupt command**, as the interrupt is not recorded by the PIC.

```c
void send_eoi(uint8_t vector)
{
    // Get the ISR number
    uint8_t isr = vector - 0x20;

    // Request read from ISR
    asm_outb(0x20, 0x0B);
    asm_outb(0xA0, 0x0B);

    // If master PIC
    if (isr < 8) {
        // Check for spurious interrupt
        if (isr != 7 || (asm_inb(0x21) & 0b10000000) == 0) {
            asm_outb(0x20, 0x20); // Send EOI
        }
    }
    // If slave PIC
    else
    {
        // Check for spurious interrupt
        if (isr != 15 || (asm_inb(0xA1) & 0b10000000) != 0)
        {
            asm_outb(0x20, 0x20); // Send EOI (master)
            asm_outb(0xA0, 0x20); // Send EOI (slave)
        }
    }
}
```
