---
title: "Processes and Threads"
permalink: /the-kernel/processes-and-threads
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

### Processes

Processes are essentially "bubbles" in which code executes. The kernel uses processes to control what memory is visible and accessible to code, and to track which resources (such as files, hardware access, etc.) the code is using and can access.

Processes also allow more than one instance of the same program to run in parallel. Programs can be started in new processes, which allow them to have different views of memory, and to have access to different files.

For example, each of the two processes open for the same calculator program can store and process different values, even though they may be accessing the same address in memory.

### Threads

While processes manage access to external resources, such as memory and files, threads isolate execution.

As we've seen in [earlier](/x86-assembly/registers-arithmetic) [sections](/x86-assembly/control-flow), during execution, code uses both registers and the stack to store values that it's working on.

As a result, we can allow multiple instances of the same code to run at the same time by giving each instance its own set of registers and its own stack. This way, instances of the same code can't interfere with each other, except when they write to memory.

We call each stack and set of registers a _Thread_. All code executes within some thread.

As threads see the same memory, they can communicate with each other simply by writing and reading to/from memory. However, code must be specifically written to run safely in more than one thread at a time.

As code within threads accesses memory and files (and other resources), threads must exist within a Process, which controls what memory they see and what resources they can access.

## Virtual Memory

The different view of memory that each process sees is due to _virtual memory_. Virtual memory allows the kernel to create "fake" RAM, such that the processor can intercept memory accesses to re-direct them anywhere in real RAM and to check if access to those memory locations is allowed.

Virtual memory is covered in detail in the [Paging](/the-kernel/paging) section.

## Context Switching

Most operating systems support multi-tasking, where more than one thread can be running on the system. This doesn't actually require more than one processor. The kernel swaps execution on the processor between threads and processes.

Threads are allowed a certain amount of time to execute before the kernel switches to another thread. This is covered in more detail in the [Scheduling](/the-kernel/scheduling) section.

This switching between threads and/or processes is called _context-switching_. Switching between threads requires doing at least the following:

1. Pausing (interrupting) current thread's execution
1. Saving the current thread's stack and registers
1. Changing the stack to point to the next thread's
1. Restoring the next thread's saved registers
1. Jumping to the address where the next thread was previously executing

Switching between threads in different processes also involves changing the current virtual memory (page table).

As interacting directly with registers requires assembly, the function `utils_context_switch` has been provided to perform this task for you. **It can only be called from code in ring 0**.

It takes two arguments, both pointers to the threads' registers. The `registers` struct **must have the same layout** as shown in the example code later in this section.

Its implementation is provided here in pseudocode:

```c
void utils_context_switch(const registers* to, const registers* from)
{
    save_registers(from);
    restore_registers(to);
    ((void(*)())to->eip)(); // Jump to previous address (does not return)
}
```

### Implementation [Advanced - Skip if not using Assembly]

Storing and restoring registers can be done either with a `mov` instruction for each register or with the `pushad` and `popad` instructions, which push and pop the general-purpose registers to and from the stack respectively.

It will also be necessary to store and restore the [segment registers](/protected-mode/segmentation2). **These can only be moved via registers**. Moving from a memory location, e.g. `mov ds, [0x8000]`, is invalid.

Ensure that you use the correct stack segment when accessing both the original (before the switch) stack and target (after the switch) stacks.
{: .notice--danger}

To change the code segment register (`cs`), you can use a far-return instruction. Far-return is the opposite of the far-call instruction we have seen [previously](/x86-assembly/segmentation1). Instead of popping only the return address, like a normal `ret` does, it first pops the new value for the `cs` register.

However, the behaviour of far-ret changes when moving between rings. If moving from a higher ring (i.e. ring 3) to a lower ring (i.e. ring 0) is not permitted with a far-ret. Instead you must use a [system call](/user-programs/syscalls).

Otherwise, **if returning from a lower ring to a higher ring** (switching from kernel to user), the far-ret will change the `ss` and `esp` registers for you. To use a far-ret from lower to higher rings, the stack must look like the following:

| Offset from `ESP` | Value |
| ------- | ----- |
| + 0 | Address (`eip`) to which to return |
| + 4 | New code segment (`cs`) |
| + 8 | New stack address (`esp`) |
| + 12 | New stack segment (`ss`) |

The provided function, `utils_context_switch`, gives an example implementation of context switching using this method.

## Standard Input/Output

Most operating systems provide a common way for programs to receive input and to produce output. This is generally done via pseudofiles - resources which pretend to be files on a filesystem.

On Linux and Windows, all processes can open a pseudofile called `stdin`, from which they can read input data passed to the process, and a pseudofile called `stdout`, to which they can write the process' output data.

There's commonly a third pseudofile, known as `stderr`, to which processes can write error data.
{: .notice--info}

Consoles use these pseudofiles to allow interaction with processes.

```bash
 $ date
Thu Jan  1 00:00:00 STD 3018
```

Here the console starts a new process for the `date` program. The `date` program writes the text "Thu Jan  1 00:00:00 STD 3018" to the `stdout` file.

Because it's a pseudofile, instead of being written to a real file, it's written to a buffer, possibly within the kernel, which the console can also open and read from.

The console reads all that it can from the file and draws it to the screen. The `date` program exits, which closes the `stdout` pseudofile and stops the console from reading it.

Interaction with `stderr` and `stdin` works in much the same way.

----

# Implementation

The kernel must keep track of what processes and threads are currently executing. The kernel itself also counts as a process, albeit one with access to everything. The kernel also has threads, although in the workshop we've only had a single kernel thread.

## Data Structures

We need to define data structures to represent processes and threads within the kernel. Below is an example of how you might do that.

**The `registers_x86` struct used in this example has the exact layout expected by the `utils_context_switch` function.**

```c
/* Holds all of the x86 registers used by each thread
   (except for SSE registers).
*/
struct registers_x86
{
    unsigned cs;
    unsigned ds;
    unsigned ss;
    unsigned fs;
    unsigned gs;
    unsigned eax;
    unsigned ecx;
    unsigned edx;
    unsigned ebx;
    void*    esp;
    void*    ebp;
    unsigned esi;
    unsigned edi;
    unsigned eflags;
    void*    eip;
}
// The attribute 'packed' ensures that this struct
// will be exactly the size and layout we've specified.
// Without it, gcc can add extra bytes (padding) between
// fields.
__attribute__((packed));

// This allows us to omit the 'struct' before 'registers_x86
// when using it
typedef struct registers_x86 registers_x86;


/* Struct representing a thread */
struct thread
{
    unsigned      id;          // Id for this thread
    registers_x86 state;       // Register values upon context-switch
    void*         stack;       // Pointer to the thread's stack
    unsigned long stack_size;  // Size of the thread's stack
};
typedef struct thread thread;


/* Page table, used in virtual memory -
 * we'll cover this in the Paging section. */
struct page_table { } __attribute__((packed));
typedef struct page_table page_table;


/* Struct representing a process */
struct process
{
    unsigned      id;              // If for this process
    const char*   name;            // Process' name
    thread*       threads;         // Array of process' threads
    unsigned long thread_count;    // Number of process' threads
    page_table*   virtual_memory;  // Process' virtual memory
};
typedef struct process process;
```

## Running Processes

```c
// You must create a process and thread for the kernel in order to switch back
process kernel_process;
thread kernel_threads[1];

// Make things easier by storing the current thread and process
thread* current_thread = &kernel_threads[1];
process* current_process = &kernel_process;

// Code to run within 'example' process
void example_process()
{
    // This is now running in your process on your thread!
    // This is still in ring 0

    // Change virtual memory (see Paging)
    asm_set_cr3(kernel_process.virtual_memory);

    // You cannot return from here. Where would you return to?
    // Instead you must context-switch back to a kernel thread
    utils_context_switch(&kernel_threads[0].state, current_thread->state);
}

// Example code for setting the fields for the kernel process
void init_kernel_process()
{
    kernel_process.id             = 0;
    kernel_process.name           = "kernel";
    kernel_process.threads        = kernel_threads;
    kernel_process.virtual_memory = (page_table*)asm_get_cr3();
    kernel_process.thread_count   =
        sizeof(kernel_threads) / sizeof(kernel_threads[0]);

    // state for kernel thread will be set when we first
    // context switch
}

/* Code to run 'example' process. Performs the following:
 *
 * 1. Create 'example' process
 * 2. Context-switch to new process
 * 3. Run new process until finished
 */
void run_example_process()
{
    // Create page table (TODO) and stack
    page_table vmem;
    unsigned char stack[1024];

    // Create thread for our process
    thread threads[1];

    // Set id and stack
    threads[0].id         = 1;
    threads[0].stack      = stack + sizeof(stack);
    threads[0].stack_size = sizeof(stack);

    // Initialise registers - these are good defaults for a ring 0 process
    threads[0].state.cs  = 0x08;             // See Segmentation II
    threads[0].state.ss  = 0x10;             //         ''
    threads[0].state.ds  = 0x10;             //         ''
    threads[0].state.ebp = threads[0].stack; // See Control Flow
    threads[0].state.esp = threads[0].stack; //       ''

    // Set the address from which the thread will start running
    threads[0].state.eip = (void*)example_process;

    // Create process and set fields
    process p1;
    p1.id             = 1;
    p1.name           = "example":
    p1.threads        = threads;
    p1.thread_count   = 1;

    // For now we're going to use the same virtual memory as the kernel
    p1.virtual_memory = (page_table*)asm_get_cr3();

    // Set the current process and thread to the one to which we're jumping
    current_process = &p1;
    current_thread  = &p1.threads[0];

    // Perform the context switch
    asm_set_cr3(p1.virtual_memory); // Change virtual memory
    utils_context_switch(p1.threads[0], &kernel_threads[0]);

    // Set the current process/thread back to the kernel
    current_process = &kernel_process;
    current_thread  = &kernel_threads[0];
}
```

# Exercises

## Exercise 1

1. Write, or copy from the example, code to describe processes and threads
1. Create a process and thread to represent the current kernel thread

## Exercise 2

1. Following exercise 1, create and fill-out another process instance
1. Create a single thread instance for your process and assign it a stack and a function
1. Context-switch to your new thread
1. In your new thread, context-switch back to the kernel

## Exercise 3

1. Following exercise 2, create more thread instances for your new process
1. Add an integer global variable (`int counter = 0;`)
1. Create a function to increment the global variable and then context-switch back to the kernel
1. Loop through the new threads, assign a stack and the function to each, and context-switch to them
1. Print your counter - it should be equal to the number of threads

## Exercise 4

1. Following **exercise 2**, when creating the thread, change the default values for the `cs`, `ss` and `ds` registers to be `0x18`, `0x20`, and `0x20` respectively. This will run your thread's code in ring 3 (user mode)
1. In your thread's function, print a message and then try to context-switch back to the kernel
1. Your message should print, but your code will not complete - switching back into kernel mode is not allowed from user mode. To do this, you will need to use a [system call](/user-programs/syscalls), which we will cover later
