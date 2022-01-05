/*
  File: disp7seg.h

  7 segment display driver
*/

#ifndef _DISP7SEG_H_
#define _DISP7SEG_H_

#include <stdint.h>
#include "system.h"


void disp7seg_write_dig(uint8_t dig, uint8_t x);
void disp7seg_write_hex(uint32_t x);

#endif