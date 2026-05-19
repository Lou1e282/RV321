.section .text
.global _start

_start:
    la sp, stack_top

    call kernel_main

hang:
    j hang

.section .bss
.align 4

stack:
    .space 4096   # stack size

.global stack_top
stack_top:

