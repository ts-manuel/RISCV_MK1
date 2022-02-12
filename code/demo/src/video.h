/*
  File: video.h

  VGA video generator driver
*/

#ifndef _VIDEO_H_
#define _VIDEO_H_

#include <stdint.h>
#include "system.h"

#define VIDEO_WRITE_FIFO(base, x)   AV_WRITE_DWORD(base, x)

#define VIDEO_GET_STATUS(base)      AV_READ_DWORD(base+4)
#define VIDEO_CLR_FIFO(base)        AV_WRITE_DWORD(base+4, 0)

#define VIDEO_SET_CLK(base, clk_div, h_div, v_div)  AV_WRITE_DWORD(base+8, (((uint32_t)clk_div & 0xf)<<8) | (((uint32_t)h_div & 0xf)<<4) | (((uint32_t)v_div & 0xf)<<0))

#endif