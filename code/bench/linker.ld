

 OUTPUT_ARCH( "riscv" )

 /* Entry Point */
 ENTRY( _start0 )

_Min_Heap_size  = 0x000; /* Required amount of heap */
_Min_Stack_size = 0x400; /* Required amount of stack */

/* Memories definition */
MEMORY
{
  rom   (rx)  : ORIGIN = 0x00000000,  LENGTH = 160K   /* Read only and Execute */
  ram   (w)   : ORIGIN = 0x04000000,  LENGTH = 64M	  /* Read only and Read/Write */
}

PROVIDE( __estack$ = ORIGIN(ram) + LENGTH(ram));

PROVIDE( __global_pointer$ = _gp);

SECTIONS
{
  /* The program code and other data into "FLASH" Rom type memory */
  .text :
  {
    . = ALIGN(4);
    *(.start) 
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */

    . = ALIGN(4);
    _etext = .; */       /* define a global symbols at end of code */
  } > rom

  /* Initialized data sections into "RAM" Ram type memory */
  .data : 
  {
    . = ALIGN(4);
    _sdata = .;        /* create a global symbol at data start */
    *(.data)           /* .data sections */
    *(.data*)          /* .data* sections */
    *(.sdata)
    *(.sdata*) 

    . = ALIGN(4);
    _edata = .;        /* define a global symbol at data end */
  } > ram AT > rom

    /* Constant data into "FLASH" Rom type memory */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)        /* .rodata  sections (constants, strings, etc.) */
    *(.rodata*)
    *(.srodata)       /* .srodata sections (small read only) */
    *(.srodata*)
    *(.init)
    *(.init*)
    *(.fini)
    *(.fini*)

    . = ALIGN(4);
  } > rom

  /* Have _gp point to middle of sdata/sbss to maximize displacement range */
  . = ALIGN(16);
  _gp = . + 0x800;

  /* Uninitialized data section into "RAM" Ram type memory */
  . = ALIGN(4);
  .bss :
  {
    _sbss = .;
    *(.bss)
    *(.bss*)
    *(.sbss)
    *(.sbss*)
    *(COMMON)

    . = ALIGN(4);
    _end = .;
  } > ram

  /* User heap stack section, used to check that there is enought "ram" memory left */
  .user_heap_stack :
  {
    . = ALIGN(8);
    . = . + _Min_Heap_size;
    . = . + _Min_Stack_size;
    . = ALIGN(8);
  } > ram

}