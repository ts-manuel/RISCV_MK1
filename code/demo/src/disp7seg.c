/*
  File: disp7seg.c

  7 segment display driver
*/


#include "disp7seg.h"


const uint8_t map[16] = {
  0b11000000, //0
  0b11111001, //1
  0b10100100, //2
  0b10110000, //3
  0b10011001, //4
  0b10010010, //5
  0b10000010, //6
  0b11111000, //7
  0b10000000, //8
  0b10010000, //9
  0b10001000, //A
  0b10000011, //B
  0b11000110, //C
  0b10100001, //D
  0b10000110, //E
  0b10001110  //F
};


void disp7seg_write_dig(uint8_t dig, uint8_t x)
{
  if (dig >= 0 && dig <= 5)
    ALT_PIO_WRITE(_ALT_PIO_7SEG_0 + 0x10 * dig, map[x & 0x0f]);
}

void disp7seg_write_hex(uint32_t x)
{
  for (int i = 0; i < 6; i++)
  {
    disp7seg_write_dig(i, x >> 4*i);
  }
}