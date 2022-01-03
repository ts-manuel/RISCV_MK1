#########################################
# File: boot.s
#
# RISC-V boot code
#
#########################################
 
.section .text
.align 4
.globl _start

_start:
    /* Setup the global pointer, which the ABI assumes points to the
     * __global_pointer$ symbol */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* Setup the stack pointer */
    la sp, __estack$

    /* Call main, leaving the arguments undefined */
    call main

    /* Spin after main() returns */
1:
    j 1b
