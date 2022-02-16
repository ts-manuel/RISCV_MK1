/*
  File: system.h

  Defines for the pheripherals on the system bus
*/


#ifndef _SYSYEM_H_
#define _SYSYEM_H_

#include <stdint.h>

#define CLK_FREQ 50000000UL


#define _ALT_JTAG_UART      0x20000000
#define _ALT_PIO_LEDS       0x20000010
#define _ALT_PIO_7SEG_0     0x20000020
#define _ALT_PIO_7SEG_1     0x20000030
#define _ALT_PIO_7SEG_2     0x20000040
#define _ALT_PIO_7SEG_3     0x20000050
#define _ALT_PIO_7SEG_4     0x20000060
#define _ALT_PIO_7SEG_5     0x20000070
#define _AV_STEREO_DAC      0x20000100
#define _AV_VIDEO_GEN       0x20000200
#define _AV_TIMER           0x20000300


#define AV_WRITE_BYTE(base, x)  *( (volatile uint8_t*)(base)) =  (uint8_t)(x)
#define AV_WRITE_WORD(base, x)  *((volatile uint16_t*)(base)) = (uint16_t)(x)
#define AV_WRITE_DWORD(base, x) *((volatile uint32_t*)(base)) = (uint32_t)(x)

#define AV_READ_BYTE(base)      (*( (volatile uint8_t*)(base)))
#define AV_READ_WORD(base)      (*((volatile uint16_t*)(base)))
#define AV_READ_DWORD(base)     (*((volatile uint32_t*)(base)))

// Altera PIO
#define ALT_PIO_WRITE(base, x)  AV_WRITE_DWORD(base, x)

#endif