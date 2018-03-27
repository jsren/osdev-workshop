---
title: "System Calls"
permalink: /user-programs/syscalls
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

With paging and rings we can switch a processor into ring 3 and let it run any user code. Paging will protect the code from accessing kernel data (for security and reliability) and ring 3 will stop the code from running any system "privileged" instructions.

However, user programs often require to interact with OS-managed resources, such as files, and to ask the kernel to perform functions such as creating threads, interacting with external devices, and destroying the process (exiting).

[Wikipedia](https://en.wikipedia.org/wiki/System_call#Categories_of_system_calls) has a comprehensive list of the kind of requests that system calls fulfil.

A simple way of requesting things from the kernel is for the process to send a request onto some message queue visible to the kernel, and wait until the scheduler context-switches back to  a thread in the kernel for it to process the request.

There are a couple of issues with this approach, however:

1. This requires the kernel to be running all of the time to poll the message queue
1. There will be a significant delay between requests and responses
1. A context switch is required to process even the most simple request

Performance is hugely important in kernels, and performing system actions like opening and writing to files can make up a surprisingly large proportion of execution time. It's perfectly possible for applications to request things of the kernel many thousands of times a second.

## Enter the System Call

A faster approach to making requests of the kernel is to remain within the same process. This may seem very counter-intuitive at first, but it has many benfits.

**A system call is a way of switching back into ring 0, running some _kernel_ code, and then returning back to ring 3, and the program's code, with the result.**

The system call doesn't perform a full context switch: although the kernel code may do things like switch the page table and stack, it doesn't have to.

Importantly, the user program loses complete control - control is swapped over to the kernel code until it returns. This keeps execution secure.

A side-effect of system calls is that they require the kernel code to be present in the address space of the program. This is okay so long as we mark the pages as being inaccessible by ring 3.

Thus when we actually create processes, the kernel must map some kernel pages into each process' address space to enable system calls.

## Implementing System Calls

The simplest way to implement a system call is via an interrupt. Recall that interrupts switch into ring 0 before executing. Therefore we can trigger our own custom interrupt in order to securely enter the kernel.

First we must pick an interrupt number to use and install an interrupt service routine (handler) for that interrupt. This will be the function that will be called when the interrupt is raised. In this function we will process the system call.

Linux on x86 uses interrupt number **0x80**, and as a result we can be at least a little certain that other devices do not use it, making it a good choice for a system call interrupt.

```c
    /* --------- IN THE KERNEL CODE --------- */

    void handle_system_call(void) {
        // handle call here - this will run in ring 0
    }

    // Register the interrupt handler
    utils_interrupt_handlers[0x80] = handle_system_call;

    /*  --------- IN THE USER CODE --------- */

    // Trigger the interrupt (system call)
    asm_int(0x80);
```

## Passing Arguments via Memory

System calls generally pass arguments via [registers](/x86-assembly/registers-arithmetic), which requires some assembly programming. If you wish to avoid using assembly, there are other methods - for example by using a hard-coded address in memory.

Passing arguments by memory is a little more tricky - the kernel must expose the same hard-coded address which all processes make use of. This requires having a virtual page at that address which points to a different physical page for each process.

The following C code shows an example of how to pass arguments to a system call via a hard-coded address:

```c
    /* --------- IN BOTH KERNEL AND USER CODE --------- */

// Define a common structure for passing system call arguments
struct system_call_args
{
    unsigned char function;
    unsigned long arg1;
    unsigned long arg2;
    unsigned long arg3;
    long result;            // Set by system call
};

// Pointer to hard-coded address, here 0x8000 (start of page 3),
// where args will be stored. Once paging is enabled, you must make sure
// that you map page 3 to a physical page so that this works.
//
// The keyword 'volatile' (should) prevent GCC from optimising away writes to this
// address, since it's unlikely that your code will read from it.
volatile struct system_call_args* syscall_args =
    (volatile struct system_call_args*)0x8000;


    /* --------- IN THE KERNEL CODE --------- */

// Function called to handle system call interrupt (0x80)
// This lives in the kernel, but uses the address space of the process
void handle_system_call(void)
{
    // Now in ring 0...
    if (syscall_args->function == 0x01)
    {
        // ... handle system call...

        // Set result
        syscall_args->result = 0;
    }
    // else if (syscall_args->function == ...
    else {
        syscall_args->result = -1;
    }
}

// Register the interrupt handler
utils_interrupt_handlers[0x80] = handle_system_call;


    /* --------- IN THE USER CODE --------- */

// This function will perform a system call with an argument.
// In this example the syscall will request the kernel to end the process
//
// The function can be called from a user-mode (ring 3) program.
int syscall_exit(int exitCode)
{
    // Set up system call arguments
    syscall_args->function = 0x01; // In this example 0x01 represents 'exit'
    syscall_args->arg1 = exitCode;

    // Tigger the system call interrupt
    asm_int(0x80);

    // Return result
    return syscall_args->result;
}
```

## Passing Arguments via the Stack

As an alternative, if assembly is more your style, you can use [inline assembly](https://wiki.osdev.org/Inline_Assembly) to pass arguments via the stack:

```c
// Function called to handle system call interrupt (0x80)
void handle_system_call(unsigned function, int arg0, int* result)
{
    // handle call here - this will run in ring 0
    *result = 0;
}

// Register the interrupt handler
utils_interrupt_handlers[0x80] = (void(*)())handle_system_call;

// This function will perform a system call with an argument.
// In this example the syscall will request the kernel to end the process
//
// The function can be called from a user-mode (ring 3) program.
int syscall_exit(int exitCode)
{
    int result;
    volatile __asm__(
        ".intel_syntax noprefix\n" // Switch to Intel syntax assembly
        "push %1\n"                // Push pointer to result
        "push %0\n"                // Push exit code
        "push 0x01\n"              // Push function number
        "int  0x80\n"              // Trigger interrupt (system call)
        "pop  %0\n"
        "pop  %0\n"                // Pop the three arguments
        "pop  %0\n"
        ".att_syntax prefix"       // Restore AT&T syntax

        : "r"(exitCode), "=m"(&result) // Define outputs
        : "r"(exitCode)                // Define inputs
    );
    return result;
}
```

Note that any code involving manual modification of the stack
(including all interrupt handlers) in **x64** must be compiled with `-mno-red-zone`.
{: .notice--danger}

-----

# The `sysenter` Instruction [Advanced]

Using interrupts is a simple and effective mechanism for switching into the kernel.
However, it's also very slow. To combat this, Intel and AMD introduced specific
instructions for performing system calls.

These calls are much faster, but are more complex to use. Use of the `sysenter` instruction
requires the [GDT](/protected-mode/segmentation2) to have a specific layout and requires manually storing the return address and original stack.

`sysenter` jumps to a target address and switches into ring 0. To return to ring 3,
you use the companion `sysexit` instruction.

## GDT Layout

`sysenter` requires the following entries in this exact layout somewhere within the GDT:

| Base | Limit | Ring | Description |
| ---- | ----- | ---- | ----------- |
| .. | ... | ... | .. _preceding entries_ ..  |
| 0x0 | 0xFFFFFFFF | 0 | Kernel Code Segment |
| 0x0 | 0xFFFFFFFF | 0 | Kernel Stack Segment |
| 0x0 | 0xFFFFFFFF | 3 | User Code Segment |
| 0x0 | 0xFFFFFFFF | 3 | User Stack Segment |
| .. | ... | ... | .. _further entries_ ..  |

## Calling `sysenter`

`sysenter` works by setting the stack pointer and stack segment to a target value, then switching to ring 0 and jumping to a target address.

You write the target address, stack pointer and stack segment to a special type of register known as a _model-specific register_ (MSR). To write to these registers, you must use the `wrmsr` instruction (see [here](http://www.felixcloutier.com/x86/WRMSR.html) for details).

| MSR Name | Number | Description |
| -------- | ------ | ----------- |
| IA32_SYSENTER_CS | 0x174 | Target Code Segement Selector
| IA32_SYSENTER_ESP | 0x175 | Target Stack Pointer |
| IA32_SYSENTER_EIP | 0x176 | Target Address |

Once you finish the system call, you return to ring 3 using the `sysexit` instruction.
This takes two parameters via the `ecx` and `edx` registers. `sysexit` changes the stack
pointer to the value in `ecx`, switches to ring 3 and jumps to the address in `edx`.

## Example Implementation

In the kernel (ring 0) code:

```nasm
section .data
syscall_stack_end:
    resb 1024                 ; reserve space for initial syscall stack
syscall_stack:
    resb 128                  ; (reserve for stack red-zone)

section .text
enable_sysenter:
    mov ecx, 0x174            ; set the syscall Code Segment selector
    mov eax, 1 << 3
    mov edx, 0
    wrmsr

    mov ecx, 0x175            ; set the syscall esp (stack pointer)
    mov eax, syscall_stack
    mov edx, 0
    wrmsr

    mov ecx, 0x176
    mov eax, handle_sysenter  ; set the syscall target address
    mov edx, 0
    wrmsr
    ret

handle_sysenter:
    push edx                  ; store return address & stack
    push ecx

    ; ... handle ... (Limited stack space - switch esp to another ASAP!)

    pop ecx
    pop edx
    sysexit                   ; sets esp to ecx and jumps to edx
```

In the user (ring 3) code:

```nasm
system_call:
    mov ecx, esp      ; manually save the stack pointer
    mov edx, .resume  ; and return address

    sysenter          ; switch to the kernel

.resume:              ; will resume here
    ret
```
