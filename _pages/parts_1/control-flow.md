---
title: "Control Flow"
permalink: /x86-assembly/control-flow
layout: archive
author_profile: true
sidebar:
    nav: "toc"
---

## Introduction

[Registers and Arithmetic](/x86-assembly/registers-arithmetic) covered performing basic
operations on data in registers, memory and immediate values. These allow us to express
simple expressions such as `a + b` in assembly.

This section will cover how to write constructs like `if` statements, `for` loops and
to create and call functions in assembly.

## Labels

Labels are names which we give to particular lines of assembly. These names allow us to
refer to locations within our assembly code, both instructions and data.

The assembly syntax for labels is the name of the label followed by a colon, e.g. `my_label:`.
Labels follow the same rules for naming as for functions in C or Java.


#### Example 1: Using data and code labels

```nasm
my_var: dd 3           ; <- this is a data label

main:                  ; <- this is a code label
    mov eax, [my_var]  ; Loads 3 into eax
add3:                  ; <- this is another code label
    add eax, 3
```

Note that labels do not automatically create functions. They do not alter the assembly
in any way - they just point to particular lines. As a result, were Example 1 to be executed,
the instruction at `main` would run, and then the next instruction would be the one at `add3`.

## Jumping

### Unconditional Jumps

Using code labels allows us to create constructs like loops. The **`jmp`** instruction in x86 allows us
to set the next instruction ("jump") to a particular label.

#### Example 2: Add 3 forever

```nasm
main:
    add eax, 3
    jmp main
```

Example 2 shows some code which will execute in a loop, running `add eax, 3` and then
jumping back to `main` and running `add eax, 3` again. The same assembly could be written in C as:

```c
    while (1) {
        eax += 3;
    }
```

### Conditional Jumps

If we don't want our loops to be infinite, we can add a condition to the jump. To do this, first we
perform a comparison between two values using the **`cmp`** instruction. Then we use one of the variants
of the `jmp` instruction to decide whether to jump or not.

If a jump is not performed, the processor just executes the instruction on the next line.

| Instruction | Description |
| ----------- | ----------- |
| `jmp` | Always jumps |
| `je` | Jumps if the comparison was equal |
| `jne` | Jumps if the comparison was not equal |
| `jz` | Jumps if the value was zero |
| `jnz` | Jumps if the value was not zero |
| `jl` | Jumps if less than |
| `jg` | Jumps if greater than |
| `jle` | Jumps if less than or equal |
| `jge` | Jumps if greater than or equal |

#### Example 3: Add 3 while less than 30 in assembly and C

```nasm
main:
    add eax, 3
    cmp eax, 30
    jl main
    sub eax, 10
```

```c
    while (eax < 30) {
        eax += 3;
    }
    eax -= 10;
```

## Functions

Functions in assembly are similar to those in other programming languages.

#### Example 4: Perform 3 + 9 and return

```nasm
add3:
    enter         ; enter/leave will be explained soon!
    add eax, 3
    leave
    ret           ; ret returns with the result in EAX

main:
    enter
    mov eax, 9
    call add3     ; Call the function
    leave
    ret           ; return
```

We name functions using labels. Functions are called with the **`call`** instruction.
Functions return using the **`ret`** instruction.

Function calls are another place where certain registers play a special role. When a
function returns, it places its return value (output) in the `EAX` register.

### The Stack

Calling functions creates a few problems. Firstly, if you call a function, that function
will probably use various registers, which may overwrite values you're currently using.

Secondly, functions could come from some other code - we can call functions written in other
programming languages, like C, and those functions may already have been assembled and we may
not be able to change them.

As a result, we need an agreed way to pass parameters and to not overwrite register values.

Thirdly, functions may require to store more intermediate/temporary values than there are registers
available.

The Stack offers a solution to all of these problems. The stack is an area of memory (RAM) which
functions can use to store data. The stack is similar to registers, except it's much larger and much
slower.

#### Example 5: Perform 3 + 5 and return

```nasm
main:
    enter
    push 3    ; Push argument 2
    push 5    ; Push argument 1
    call sum  ; Call sum, result is in EAX
    leave
    ret
```

Items are added ("pushed") onto the stack with the `push` instruction, and removed
with `pop`. The stack, as the name suggests, is last-in-first-out (LIFO) - in other words,
`pop` removes the _most recent_ item you added. Another explanation is [here](https://simple.wikipedia.org/wiki/Stack_(data_structure)).

So to pass arguments to a function, we push the arguments in **reverse order**, so if we have two arguments,
we `push` the _second_ argument first, and then the first argument. Then the function using the arguments can
access them on the stack.

Functions can also `push` values if they're too large to fit in registers or to store register values safely
before calling another function.

x86 uses two registers to keep track of the stack: `ESP` and `EBP`. `ebp`, or the base pointer
(also known as the frame pointer), is used to point to the start of the stack, and `esp`, the stack pointer,
points to the end.

The stack pointer (`esp`) is automatically updated by `push` and `pop`. However, the base pointer (`ebp`)
is not. To keep `ebp` updated, we use the **`enter`** and **`leave`** instructions. `enter` must be the first
instruction in each function and `leave` must be put directly before `ret`.

#### Example 6: Function for adding two numbers

```nasm
sum:
    enter
    mov eax, [esp + 4]
    mov ecx, [esp + 8]
    add eax, ecx
    leave
    ret

main:
    enter
    push 3
    push 5
    call sum   ; Result in eax
    leave
    ret
```

```c
unsigned int sum(unsigned int eax, unsigned int ecx) {
    return eax + ecx;
}
int main()
{
    return sum(5, 3);
}
```

Once inside a function, arguments on the stack must be accessed via the stack pointer (`esp`), not via
`pop`. In x86, each entry on the stack is 4 bytes wide, even if you push a single byte.

The stack has one more trick up its sleeve - it _grows downwards_, in other words, as you push more things
on the stack, `esp` gets smaller, not larger, and vice-versa.

Putting this together, the first argument is at address `esp + 4`, the second is at `esp + 8`,
the third is at `esp + 12` and so on. Example 6 gives a demonstration of this.

### CDECL and Calling Conventions

The rules used for how to pass arguments, return values and which registers to save are known collectively
as a _calling convention_. The most well-known of these for x86 is "cdecl". Cdecl was created for the C
programming language.

In cdecl, arguments are passed on the stack as previously described and values are returned in `eax`.
However, there are additional rules for how registers may be used by functions.

Cdecl specifies that code which calls a function must allow the registers `eax`, `ecx` and
`edx` to be changed by the called function. If you wish to preserve values in these registers
you can move them to other registers or push them onto the stack and pop them back after the
function call.

Equally, if functions which have been called from other functions wish to modify the `ebx`,
`esi` or `edi` registers, they must ensure that their original values are
restored before they return.

```nasm
sum:
    enter
    mov eax, [esp + 4]
    mov ecx, [esp + 8]
    add eax, ecx
    leave
    ret

main:
    enter
    mov eax, 5    ; Compute 5 + 3 in eax
    add eax, 3

    push eax      ; Must store eax in case used by 'sum'
    push ecx      ; If using ecx and edx, store these too
    push edx

    push 8        ; Push argument 2
    push 16       ; Push argument 1
    call sum      ; Result in eax

    mov esi, eax  ; Move result of addition to esi

    pop edx
    pop ecx
    pop eax       ; Restore previous values

    add eax, esi  ; Add previous value to result of call to sum

    leave
    ret           ; Returns with 32 ((5 + 3) + (8 + 16)) in eax
```

```c
unsigned int sum(unsigned int eax, unsigned int ecx) {
    return eax + ecx;
}
int main()
{
    unsigned eax = 5 + 3;
    unsigned esi = sum(16, 8);
    return eax + esi;
}
```

`push x` is the same as `sub esp, 4`, `mov [esp], x`. And equally `pop x` is `mov x, [esp]`, `add esp, 4`.
{: .notice--info}

`call` and `return` make additional use of the stack. `call` pushes the address of the instruction to return to
and `ret` pops this instruction and jumps to it. This is why you must use `esp + 4` to access the first parameter -
`[esp]` has the return address.
{: .notice--info}

To return a value larger than can fit in `EAX` you can either split the value between
multiple registers, or, as is more common, you can pass an address as an additional
argument to which you copy the output data.
{: .notice--info}

## Exercises

### Exercise 1

### Exercise 2

### Exercise 3

### Exercise 4

### Exercise 5

### Exercise 6
