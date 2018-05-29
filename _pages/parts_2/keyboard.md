---
title: "The Keyboard"
permalink: /input-output/keyboard
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

Before USB, most keyboards and mice connected to the computer via the PS/2 connector. These were circular 6-pin ports, often coloured green and purple. The interface for working with these devices was relatively simple and easy to configure.

<img src="/assets/images/parts_2/ps-2-ports.jpg" alt="Example of PS/2 Connectors" style="width:200px"/> <br/>
<small>By <a title="User:Norm~commonswiki" href="//commons.wikimedia.org/wiki/User:Norm~commonswiki">Norman Rogers</a> - <span class="int-own-work" lang="en">Own work</span>, Public Domain, <a href="https://commons.wikimedia.org/w/index.php?curid=12584">Link</a></small>
<br/>

Today almost all keyboards and mice connect to the computer via USB. Thus interacting with the keyboard should require us to first write a USB driver, which is large and complex.

However, keyboard input is often required in early stages of power-on, such as in the bootloader, where code should aim to be small and simple.

In order to prevent the need for bootloaders and firmware to require their own USB drivers, the BIOS provides its own, and what's more, can emulate the old-style PS/2 controller, making USB keyboards look like PS/2 keyboards.

As a result, instead of diving in to the complexities of the USB stack, we will here focus on writing a PS/2 keyboard driver, which will work, thanks to the BIOS, with USB keyboards too.

Before interacting with the USB host controller in your own USB driver, this legacy keyboard support must first be disabled. This can be done via the appropriate host controller interface (e.g. EHCI).
{: .notice--info}

Note that only USB keyboards, not USB mice, support PS/2 emulation.

# The PS/2 Controller

The IBM Personal System/2 (PS/2) introduced two purpose-built connectors (known as the PS/2 ports) for connecting compatible mice and keyboards. Both ports were co-ordinated by the hardware PS/2 controller, which managed communication with the devices.

Not all controllers have two ports, as support for two is optional.

## Controller Registers

### Communication Registers

The PS/2 controller uses four internal registers for communication:

| Name | Port | Access | Description |
| ---- | ---- | ------ | ----------- |
| Status Register | 0x64 | Read-only | Has information on controller status |
| Output Buffer | 0x60 | Read-only | Reads data from the controller or keyboard |
| Command Input Buffer | 0x64 | Write-only | Sends command to controller |
| Data Input Buffer | 0x60 | Write-only | Sends data to controller or keyboard |

Each register is 8 bytes wide, and we can read from or write to these registers via I/O ports, as described in [Ports and Memory Mapping](/input-output/ports-and-memory-mapping).

Communication is typically performed by writing a command to the Command Input Buffer, and then reading response values (if any) from the Output Buffer.

### Configuration Registers

The controller also has internal registers used for configuration:

| Name | Description | Read Command | Write Command |
| ---- | ----------- | ------------ | ------------- |
| Configuration | Controls various features of the PS/2 ports | 0x20 | 0x60 |
| Output | Has status information on external lines/devices | 0xD0 | 0xD1 |
| Input | Undefined - best not to use | 0xC0 | - |

These two registers are accessed by writing commands to the Command Input Buffer (port 0x64).

Unlike the registers we've seen before, these registers are present within the PS/2 controller, not within the processor, and so cannot be read directly (e.g. using `mov`).
{: .notice--info}

Technically, there are only three registers used for communication, as the Data and Command Input Buffers are shared.
{: .notice--info}

## Communicating with the Controller

### Reading from the Status Register

The Status Register is the easiest to access. Simply read a byte from port 0x64. Reads may be performed at any time. The table below gives a partial list of the more useful flags in the Status Register.

| Bit | Value | Description |
| --- | ----- | ----------- |
| 0   | 0     | Output Buffer is empty, do not read |
|     | 1     | Output Buffer has value, can read |
| 1   | 0     | Data/Command Input Buffer is empty, can write |
|     | 1     | Data/Command Input Buffer is full, do not write |
| 2+  | -     | See [here](https://wiki.osdev.org/%228042%22_PS/2_Controller#Status_Register) for further details |

Example:

``` c
    uint8_t status = asm_inb(0x64);
```

### Using Commands

| Command | Description | Data | Response |
| ------- | ----------- | ---- | -------- |
| 0x20    | Read configuration register | - | Configuration register value |
| 0x60    | Write configuration register | Configuration register value  | - |
| 0xA7    | Disable second PS/2 port | - | - |
| 0xA8    | Enable second PS/2 port | - | - |
| 0xAD    | Disable first PS/2 port | - | - |
| 0xAE    | Enable first PS/2 port | - | - |
| 0xD0    | Read output register | Output register value | - |
| 0xD1    | Write output register | - | Output register value |
| 0xD4    | Write to second PS/2 port | Value | - |
| -       | See [here](https://wiki.osdev.org/%228042%22_PS/2_Controller#PS.2F2_Controller_Commands) for further details | - | - |

Most interaction with the controller is done via commands. Commands are written to the Command Input Buffer. In order to send a command, you must perform the following steps:

1 - Wait for the Command Input Buffer to be ready by polling bit 1 in the Status Register (port 0x64) to be 0

```c
    while (asm_inb(0x64) & 0b10 != 0) { } // wait for bit 1 to be zero
```

2 - Write the command to the Command Input Buffer (port 0x64)

```c
    asm_outb(0x64, command); // write the command
```

#### If the command takes a value

3 - Wait for the Data Input Buffer to be ready by polling for bit 1 in the Status Register to be 0

```c
    while (asm_inb(0x64) & 0b10 != 0) { } // wait for bit 1 to be zero
```

4 - Write the value to the Data Input Buffer (port 0x60)

```c
    asm_outb(0x60, value);
```

#### If the command returns a value

5 - Wait for the value to be written to the Output Buffer by polling for bit 0 in the Status Register to be 1

```c
    while (asm_inb(0x64) & 0b1 == 0) { } // Wait for bit 0 to be 1
```

6 - Read the value from the Output Buffer (port 0x60)

```c
    uint8_t value = asm_inb(0x60);
```

Here, as before, `asm_inb` and `asm_outb` emit the `inb` and `outb` assembly instructions respectively.

## Configuring the Controller

### Enabling and Disabling the Keyboard

| Command | Description |
| ------- | ----------- |
| 0xAD    | Disable first PS/2 Port |
| 0xAE    | Enable first PS/2 Port |
| 0xA7    | Disable second PS/2 Port |
| 0xA8    | Enable second PS/2 Port |

To enable or disable devices attached to PS/2 ports, simply write the necessary command byte (as given in the table above) to the Command Input Buffer (port 0x64).

For example:

```c
    // Wait for command input buffer to be free
    while (asm_inb(0x64) & 0b10 != 0) {}
    // Write command to command input buffer (disable keyboard)
    asm_outb(0x64, 0xAD;
```

### Accessing the Configuration Register

The configuration register has flags for controlling the features of the PS/2 Controller. The table below gives a partial list of the more useful flags in the configuration register.

| Bit | Value | Description |
| --- | ----- | ----------- |
| 0 | 0 | First PS/2 port interrupt disabled |
|   | 1 | First PS/2 port interrupt enabled |
| 1 | 0 | Second PS/2 port interrupt disabled |
|   | 1 | Second PS/2 port interrupt enabled |
| 2 | 1 | Always 1 (Indicates that [POST](https://en.wikipedia.org/wiki/Power-on_self-test) succeeded) |
| 3 | 0 | Always 0 |
| 4 | 0 | First PS/2 port clock enabled |
|   | 1 | First PS/2 port clock disabled |
| 5 | 0 | Second PS/2 port clock enabled |
|   | 1 | Second PS/2 port clock disabled |
| 6 | 0 | First PS/2 port translation disabled |
|   | 1 | First PS/2 port translation enabled |
| 7 | 0 | Always 0 |

To read from the register:

1. Wait for the Command Input Buffer to be free by checking that bit 1 in the [Status Register](#reading-from-the-status-register) is zero
1. Write [0x20](#using-commands) to the Command Input Buffer (port 0x64) to request the read
1. Wait for the Output Buffer to have data by checking that bit 0 in the [Status Register](#reading-from-the-status-register) is 1
1. Read from the Output Buffer (port 0x60)

Do not write to controller registers while the PS/2 ports (keyboard/mouse) are enabled. Follow [these](#enabling-and-disabling-the-keyboard) steps first.
{: .notice--danger}

To write to the register:

1. Read the current register value as shown above
1. Wait for the Command Input Buffer to be free by checking that [bit 1](#reading-from-the-status-register) in the Status Register is zero
1. Write [0x60](#using-commands) to the Command Input Buffer (port 0x64) to request the write
1. Wait for the Data Input Buffer to be free by checking that [bit 1](#reading-from-the-status-register) in the Status Register is zero
1. Alter the value read in step 1 and write to the Data Input Buffer (port 0x60)

### Accessing the Output Register

The output register has status information on external wires (lines) and devices. These flags are not generally useful for interacting with the keyboard, but support other features. The table below gives a partial list of the more useful flags in the output register.

| Bit | Description |
| --- | ----------- |
| 0   | The system reset line - **this must always be set to 1!** |
| 1   | A20 Line enable/disable |
| 2+  | See [here](https://wiki.osdev.org/%228042%22_PS/2_Controller#PS.2F2_Controller_Output_Port) for further details |

The system reset line can be used to restart the computer when the line is [**pulsed**](https://wiki.osdev.org/%228042%22_PS/2_Controller#CPU_Reset) via the 0xFE command. It is not enough to set it to 0 - on a real PS/2 controller this may result in the computer remaining fixed in the reset state and unable to start at all.
{: .notice--danger}

To read from the register:

1. Wait for the Command Input Buffer to be free by checking that bit 1 in the [Status Register](#reading-from-the-status-register) is zero
1. Write [0xD0](#using-commands) to the Command Input Buffer (port 0x64) to request the read
1. Wait for the Output Buffer to have data by checking that bit 0 in the [Status Register](#reading-from-the-status-register) is 1
1. Read from the Output Buffer (port 0x60)

Do not write to controller registers while the PS/2 ports (keyboard/mouse) are enabled. Follow [these](#enabling-and-disabling-the-keyboard) steps first.
{: .notice--danger}

To write to the register:

1. Read the current register value as shown above
1. Wait for the Command Input Buffer to be free by checking that [bit 1](#reading-from-the-status-register) in the Status Register is zero
1. Write [0xD1](#using-commands) to the Command Input Buffer (port 0x64) to request the write
1. Wait for the Data Input Buffer to be free by checking that [bit 1](#reading-from-the-status-register) in the Status Register is zero
1. Alter the value read in step 1 and write to the Data Input Buffer (port 0x60)

### Enabling the A20 Line

For cost-saving reasons, IBM placed the [A20 Gate](/x86-assembly/segmentation1#the-a20-line) (the bit enabling/disabling the A20 line) on the PS/2 controller.

In order to enable the A20 line, you must set bit 1 in the output register. The code below shows how to do this. Note that **the keyboard must be disabled** for this code to work correctly.

```c
    // Wait for input buffers to be free
    while (asm_inb(0x64) & 0b10 != 0) {}
    // Write command to command input buffer (read output register)
    asm_outb(0x64, 0xD0);
    // Wait for output buffer to have data
    while (asm_inb(0x64) & 0b1 != 0b1) {}
    // Read output register data from output buffer
    uint8_t outputByte = asm_inb(0x60);
    // Wait for input buffers to be free
    while (asm_inb(0x64) & 0b10 != 0) {}
    // Write command to command input buffer (write output register)
    asm_outb(0x64, 0xD1);
    // Wait for input buffers to be free
    while (asm_inb(0x64) & 0b10 != 0) {}
    // Write new output register data to output buffer
    asm_outb(0x60, outputByte | 0b10);

```

There are [other, faster, methods](https://wiki.osdev.org/A20_Line#Fast_A20_Gate) of enabling the A20 line, but this is by far the most reliable.
{: .notice--info}

With real hardware, you should generally perform a self-test of the PS/2 controller and with the keyboard and/or mouse. However, as PS/2 is obsolete and we're typically using the BIOS keyboard emulation, this should not be necessary, and historically the BIOS emulation code has been unstable, so it may be wise to avoid doing a self-test.
{: .notice--info}

----

# Communicating with the Keyboard

The previous section dealt exclusively with communicating with the PS/2 Controller. This section will cover how to send commands and read keys and other information from a PS/2 keyboard.

## Scan Codes

Scan Codes are sequences of one to six bytes which represent the press or release of a single key. If you receive data which is not in response to a command, and is not **0x00** or **0xFF** (internal error), then you have received a scan code.

In order to work out which key was pressed, you need a Scan Code Set, which is a table mapping each scan code to a key on a specific keyboard layout (e.g. US Keyboard Layout, UK Keyboard Layout, etc.)

To complicate matters, for each scan code set there are three variants, known as Set 1, Set 2 and Set 3, and only certain variants are supported by any one keyboard. It is suspected that the Set 2 is now the most commonly supported of the three in modern hardware.

Sets 1 and 2 can be found [here](https://wiki.osdev.org/PS2_Keyboard#Scan_Code_Set_1) for the US keyboard layout.

As a reference, code for converting scan codes into keys can be found here.

### Translation

The sets can be translated between one another, and the PS/2 Controller has a built-in ability to automatically translate Set 2 into Set 1 before the scan codes are placed into the Output Buffer.

This translation is only available for the first PS/2 port, and if enabled in [bit 6](#accessing-the-configuration-register) of the controller configuration register.

Translation may be enabled by default. Thus, in order to use scan code sets other than Set 1, you must first ensure that translation is disabled.

## Interrupts

The process for receiving data from the keyboard that we have just described has two major issues:

- When two keyboards are connected, there is no way to tell which keyboard has sent the scan code
- We must actively poll in order to receive scan codes from the keyboard

Interrupts solve both problems. We can configure the PS/2 Controller to trigger either interrupt INT1, for the first PS/2 port or INT12 for the second, when data is received from any device.

To enable these interrupts, simply set [bits 0 and 1](#accessing-the-configuration-register) in the PS/2 Controller configuration register.

```c
// Interrupt handler for INT1
void handle_int1()
{
    // Don't need to check status register -
    // interrupt means there's a byte in Output Buffer
    uint8_t value = asm_inb(0x60);

    // Check if scan code
    if (value == 0xFA || value == 0xFE)

    // If using PIC, send EOI
}
```

If the two interrupts are enabled and a subsequent PS/2 **controller** command is sent that returns data, the controller may incorrectly trigger either or neither of the two interrupts. One way to deal with this is to (gracefully) disable the PS/2 ports before sending the controller command.
{: .notice--warning}

## Keyboard Commands

| Command | Description | Data |  Response |
| ------- | ----------- | ---- | -------- |
| 0xED | Sets the keyboard LEDs | See table below | |
| 0xEE | Requests echo | | 0xEE or resend (0xFE), **no ACK** |
| 0xF0 | Gets/sets scan code set | See table below | If get, the current scan code set (1-3) |
|     | See [here](https://wiki.osdev.org/Keyboard#Commands) for more commands |

Values for command 0xED (set keyboard LEDs):

| Bit | Value | Description |
| --- | ----- | ----------- |
| 0 | 0 | Scroll Lock LED off |
|   | 1 | Scroll Lock LED on |
| 1 | 0 | Num Lock LED on |
|   | 1 | Num Lock LED off |
| 2 | 0 | Caps Lock LED on |
|   | 1 | Caps Lock LED off |

E.g. `0b111` turns all LEDs on.

Values for command **0xF0** (get/set scan code set):

| Value | Description |
| ----- | ----------- |
| 0x0 | Gets the current scan code set number |
| 0x1 | Use scan code set 1 |
| 0x2 | Use scan code set 2 |
| 0x3 | Use scan code set 3 |

## Sending Commands to the Keyboard

To send a command to the keyboard at the first PS/2 port, write the command byte to the Data Input Buffer on the controller _without_ first sending a command to the controller.

To send a command to the keyboard at the second PS/2 port, first send the command **0xD4** to the controller, and then write the keyboard command to the Data Input Buffer.

The keyboard may then respond with either **0xFA** (ACK) if the command succeeded or **0xFE** (Resend) if the keyboard requires you to resend the last command. For the Echo command, it always responds with **0xEE**.

If the keyboard command has some output, it will follow an ACK response.

Example:

```c
bool send(uint8_t command)
{
    // TODO: Have some max number of resends
    while (true)
    {
        // Wait for Data Input Buffer to be free
        while (asm_inb(0x64) & 0b10 != 0) { }
        // Send command to keyboard
        asm_outb(0x60, command);

        // Wait for value in Output Buffer
        while (asm_inb(0x64) & 0b1 == 0) { }
        // Read response from keyboard
        uint8_t response = asm_inb(0x60);

        // Return upon success (ACK)
        if (response == 0xFA) return true;
        // Resend if requested
        else if (response == 0xFE) continue;
        // Otherwise report error
        else return false;
    }
}
```

## Receiving Data from the Keyboard

In response to commands, the keyboard will send data to the Output Buffer on the controller. It can send **0x00** or **0xFF** at any time to indicate an internal error. It can also send scan codes (key presses) at any time.
