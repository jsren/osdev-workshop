---
title: "Paging"
permalink: /the-kernel/paging
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

Paging is a way of splitting up memory into same-sized individual chunks which we call pages. This doesn't just apply
to the physical memory (RAM) available, but to the entire 4GiB address space (the range of all possible memory addresses).

If each page is 4KiB, page 0 would contain addresses 0 - 4095, page 1 has 4096 - 8191, and so on.

Paging has essentially replaced segmentation in protected mode. If paging is being used, you should enforce a flat memory model, i.e. having each segment cover the entire 4GiB address space.

## Virtual Memory

Paging actually provides two different types of pages: physical pages and virtual pages. Physical pages are what
we've just described: breaking up the address space.

Virtual pages are different. With paging, the processor gives us an additional, virtual (fake) address space. This virtual
address space is the same size (4GiB), and once enabled will form a layer between our code and the real, physical address space.

This layer will allow us to redirect memory accesses. For example, the following steps are followed when code tries to write to address **0x10**:

1. The address is mapped to a virtual page (here page 0)
1. The virtual page's properties are checked to see if the access is allowed
1. The virtual page points to a physical (real) page to which to redirect the access
1. The physical page is accessed in RAM

The word _page_ normally refers to a virtual page, unless the page is explictly said to be physical.

### Identity Paging

The simplest form of mapping virtual pages to physical pages is known as _identity paging_, where each virtual page
maps to the same physical page (e.g. page 0 maps to physical page 0, and page 1 to physical page 1, etc.).

### Page Attributes

Each virtual page has certain properties, including whether it is read-only, executable, or whether it is present at all.
If instructions try to write to an address inside a virtual page which is marked as read-only, it will be prevented and a _Page Fault_ (PF) exception will be raised. The same will happen if code tries to run instructions located on a page not marked as executable.

### Guard Pages

Pages marked as not present are incredibly useful. They not only prevent reading, writing or executing memory which really
isn't there (is outside the available RAM), but can be used to catch errors and/or to implement _page swapping_.

Pages which are intentionally marked as being not present are known as Guard Pages.
There are three common uses for guard pages:

#### 1. Catching Errors

One of the most common programming errors is dereferencing a null pointer, or in other words attempting (incorrectly) to
access address 0. The problem is that address 0 is a perfectly valid address - it's a real location in memory!

Practically all programs, however, do not intend to access this address. Therefore, we can mark page 0 as being not
present. Then if code tries to access address 0, it will result in an exception. The OS can then inform the program
that the error (segfault) occurred.

#### 2. Increasing Stack Size on Demand

Programs, or more specifically threads, use an area of contiguous memory known as the stack to store data being used
during code exection. Threads use more space on the stack depending on how deep the function call graph is, and so
the stack size varies significantly during execution.

However, some threads may use little to no stack space, and so giving programs lots of stack space initally may be a
waste of memory.

To get around this problem, the kernel can allocate only a small amount of memory (small number of pages) for the stack,
**and then** put a guard page before those pages (the stack typically grows downwards).

As a result, if the thread stack grows beyond its allocated memory, an access will be attempted into the guard page.
This will raise an exception, which the kernel can catch and then allocate more pages for the stack.

#### 3. Page Swapping

Page swapping is a technique used by all modern operating systems to allow programs to use more memory than is actually
present on the system.

Page swapping works because some programs use certain areas of their allocated memory very infrequently. This allows us
to copy the contents of those pages to disk (hard drive, SSD etc.), freeing the memory (RAM) to be used by other programs.

Obviously this presents a problem - a program may still wish to use pages that have been moved ("swapped") from RAM to disk.
To solve this, the virtual pages corresponding to that memory are set to not-present.

As a result, if the program tries to access these pages, an exception will be raised. The kernel will see the exception and
will move the memory for those pages back into RAM, then re-mark the virtual page as being present, allowing the access to continue.

The location on disk in which page data is stored is known as a "swap file", "swap space" or on Windows is the _pagefile_, located at `C:\pagefile.sys`.

## Page Table

The virtual address space is implemented via a _page table_. This is the table containing the
mapping between virtual and physical pages.

Page tables are typically broken down into two levels: a top-level page directory and sections of page table.

In total there are 1024 page directory entries. Each page directory represents 4MiB of the virtual address space, and points to a table of 1024 page table entries. Each page table entry represents 4KiB of the virtual address space and points to a physical page.

<img src="/assets/images/parts_4/VirtualMemory.svg" alt="Page Table Hierarchy" style="width: 650px;"/>

### Page Directory Entry

### Page Table Entry

### Reducing the Number of Entries

The reason for the two levels is that every single page in the address space must have an entry. Given a 4GiB space and a page size of 4KiB, this requires 1,048,576 entries. However, by adding an additional level (the directories) which group entries, we can mark an entire directory as not being present, allowing us to omit the entries for that directory. By marking directories as not present, we can effectively reduce the number of entries required.

## Enabling Paging

The processor is configured to use paging via two registers: `cr0` and `cr3`.

`cr3` must contain the address of the page table (of the first page directory entry).
Once this has been assigned, you enabling by setting the _Paging (PG)_ bit, which is bit 31 in `cr0`.

Paging can only be enabled in Protected Mode.

## Updating the Page Table

The processor does not load page table entries from RAM for every memory access as this would be incredibly slow.
Instead, page table entries are cached in the _Translation Lookaside Buffer_ (TLB).

As a result, if we make changes to any of the entries in the table, we must inform the processor so that it can
force the changed entries to be reloaded from memory.

The assembly instruction `invlpg <address>` will update the entry for the page at the given address. The C function `asm_invlpg` has been provided in `utils.c` which will emit the `invlpg` instruction.

## Global Pages



## Page Fault Exceptions



## Higher-Half Kernel

Most modern operating systems partition the virtual address space into user memory and kernel memory.
Linux, for example, reserves the top 1GiB of virtual addresses for the kernel, while Windows (by default) reserves the top 2GiB. This is why on Windows on x86, programs have a maximum of 2GiB (total 4GiB - 2GiB = 2GiB) of memory they can use.

See [here](https://wiki.osdev.org/Higher_Half_Kernel) for more information.

## Physical Address Extension (PAE)

Most modern processors support a feature known as Physical Address Extension (PAE), where
the page table gains a third level, with the third level containing four entries, each pointing to a second-level page directory table.

This increases the virtual address space to a total of 64GiB of RAM.

See [here](https://en.wikipedia.org/wiki/Physical_Address_Extension) for more information.

## Page Size Extension (PSE)

Pages are usually 4KiB in size. However, as we've seen, this requires significant numbers of entries to represent each page. In order to reduce this number, you can enable Page Size Extensions, which allows for an entire page directory entry to point, instead of to a page table, to a single 4MiB page.

The use of a 4MiB page is indicated with the _Page Size_ bit on the page directory entry.

See [here](https://en.wikipedia.org/wiki/Page_Size_Extension) for more information.

# Exercises

## Enabling Paging

The assembly code to set the _PG_ bit and to load `cr3` with the page table address has been
included in the `utils.c` and `utils.h` files.

Use `asm_set_cr3(address)` to set the page table and `asm_cr0_set_pg()` to enable paging.

## Building a Page Table

Building a page table requires creating an array of 1024 page directory entries and then,
for each directory entry, either mark it as not-present or point it to the physical address
of another table of 1024 page table entries.

In total, there are 1024 * 1024 page table entries and 1024 page directory entries,
and each entry is 8 bytes wide. As a result, we need 9KiB to store the entire page table.

In our C code this is relatively simple as we can just allocate the arrays within our kernel
binary:

```c
static page_directory_entry directories[1024];
static page_table_entry pageTable[1024 * 1024];
```

## Exercise 1 - Identity Paging

1. Create a page table using identity paging and set all pages to be readable, writable and executable
1. Enable paging
1. Your code should complete as normal

## Exercise 2 - Guard Page

1. Starting from identity paging, set page 0 to be a guard page (mark as not-present)
1. Add a handler for the PF exception to print a message
1. Intentionally dereference a null-pointer (e.g. `*((volatile char*)0x0);`)
1. Your message should be printed continuously to the screen, your code will not complete

## Exercise 3 - Guard Page II

1. Starting with your code from exercise 2, change your PF exception handler
to change the page table entry for page 0 to be _present_, update that page (with `asm_invlpg((void*)0)`)
and return
1. Your message should be printed and then your code should complete as normal

## Exercise 4 - Global Pages
