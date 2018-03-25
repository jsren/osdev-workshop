---
title: "Paging"
permalink: /the-kernel/paging
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

Paging is a way of splitting up memory into same-sized individual chunks which we call pages. This just doesn't apply
to the physical memory (RAM) available, but to the entire 4GiB address space.

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

### Page Attributes

Each virtual page has certain properties, including whether it is read-only, executable, or whether it is present at all.
If instructions try to write to an address inside a virtual page which is marked as read-only, it will be prevented and an exception will be raised.
The same will happen if code tries to run instructions located on a page not marked as executable.

Pages marked as not present are incredibly useful. They not only prevent reading, writing or executing memory which really
isn't there (is outside the available RAM), but can be used to catch errors and/or to implement _page swapping_.

### Guard Pages

Guard pages are pages which are intentionally marked as being not present. There are three common uses for guard pages:

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

The assembly code to set the _PG_ bit and to load `cr3` with the page table address has been included in the `utils.c` and `utils.h` files.

Use `asm_set_cr3(address)` to set the page table and `asm_cr0_set_pg()` to enable paging.

## Exercise 1
