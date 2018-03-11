### Pointer Registers

The pointer registers are used by the processor to keep track of addresses
during execution.

| Register | Description |
| -------- | ----------- |
| `eip`/`ip` | Address of the next instruction to be executed |
| `esp`/`sp` | Address of the end of the current stack frame |
| `ebp`/`bp` | Address of the start of the current stack frame |

The `eip`/`ip` register is read-only and cannot be directly written to.

These registers will normally be changed automatically by
the processor and you shouldn't use them to store data. We will explain
in detail what these registers are used for in the next sections.

In addition to these registers are the segment registers. We will discuss their
function in [Segmentation 1](/x86-assembly/segmentation1).
