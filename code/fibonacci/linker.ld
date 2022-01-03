

 OUTPUT_ARCH( "riscv" )

 /* Entry Point */
 ENTRY( _start )

_Min_Heap_size  = 0x000; /* Required amount of heap */
_Min_Stack_size = 0x100; /* Required amount of stack */

/* Memories definition */
MEMORY
{
  rom   (rx)  : ORIGIN = 0x00000000,  LENGTH = 32K   /* Read only and Execute */
  ram   (rw)  : ORIGIN = 0x00008000,  LENGTH = 32K	 /* Read only and Read/Write */
}

PROVIDE( __estack$ = ORIGIN(ram) + LENGTH(ram));

PROVIDE( __global_pointer$ = _gp);

SECTIONS
{
  /* The program code and other data into "FLASH" Rom type memory */
  .text :
  {
    . = ALIGN(4);
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */

    . = ALIGN(4);
    _etext = .;        /* define a global symbols at end of code */
  } > rom

  /* Constant data into "FLASH" Rom type memory */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)         /* .rodata sections (constants, strings, etc.) */
    *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    . = ALIGN(4);
  } > rom

  /* Initialized data sections into "RAM" Ram type memory */
  .data : 
  {
    . = ALIGN(4);
    _sdata = .;        /* create a global symbol at data start */
    *(.data)           /* .data sections */
    *(.data*)          /* .data* sections */

    . = ALIGN(4);
    _edata = .;        /* define a global symbol at data end */
  } > ram AT > rom

  /* Have _gp point to middle of sdata/sbss to maximize displacement range */
  . = ALIGN(16);
  _gp = . + 0x800;

  /* Uninitialized data section into "RAM" Ram type memory */
  . = ALIGN(4);
  .bss :
  {
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
  } > ram

  /* User heap stack section, used to check that there is enought "ram" memory left */
  .user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    . = . + _Min_Heap_size;
    . = . + _Min_Stack_size;
    . = ALIGN(8);
  } > ram

}