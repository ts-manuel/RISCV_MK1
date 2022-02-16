/*
  File: system.h

  Hardware pheripherals memory map and read write macros
*/


#ifndef _SYSYEM_H_
#define _SYSYEM_H_

#include <stdint.h>

#define _CLK_FREQ 50000000UL


#define _ALT_JTAG_UART      0x20000000
#define _HPC_ADDR_          0x20000400


//Read Write macros
#define WRITE_BYTE(base, x)  *( (volatile uint8_t*)(base)) =  (uint8_t)(x)
#define WRITE_WORD(base, x)  *((volatile uint16_t*)(base)) = (uint16_t)(x)
#define WRITE_DWORD(base, x) *((volatile uint32_t*)(base)) = (uint32_t)(x)

#define READ_BYTE(base)      (*( (volatile uint8_t*)(base)))
#define READ_WORD(base)      (*((volatile uint16_t*)(base)))
#define READ_DWORD(base)     (*((volatile uint32_t*)(base)))

#endif