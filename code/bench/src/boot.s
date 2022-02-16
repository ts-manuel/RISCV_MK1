#########################################
# File: boot.s
#
# RISC-V boot code
#
#########################################
 
.section .start
.align 4
.globl _start0

_start0:
    /* Setup the global pointer, which the ABI assumes points to the
     * __global_pointer$ symbol. */
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop

    /* Setup the stack pointer. */
    la      sp, __estack$

    /* Copy .data segment from ROM to RAM */
    la      t0, _etext   # .data start address in ROM
    la      t1, _sdata   # .data start address in RAM
    la      t2, _edata
    sub     t2, t2, t1   # t2 = length of .data segment
1:
    beqz    t2, 2f 
    lw      t3, 0(t0)
    sw      t3, 0(t1)
    addi    t0, t0, 4
    addi    t1, t1, 4
    addi    t2, t2,-4
    j       1b
2:

    /* Zero .bss */
    la      t0, _sbss   # .bss start address
    la      t1, _end    # .bss end address
    sub     t1, t1, t0  # t1 = length of .bss segment
3:
    beqz    t1, 4f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    addi    t1, t1,-4
    j       3b
4:

    /* Jump to _start */
    j       _start
