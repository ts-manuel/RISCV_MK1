/*
  File: dac.h

  stereo dac driver
*/

#ifndef _DAC_H_
#define _DAC_H_

#include <stdint.h>

#define DAC_LR_SAMPLE(base, l, r)   *((uint32_t*)(base+0)) = ((int32_t)(l)) << 16 | ((int32_t)(r))

#define DAC_SET_CLK_DIV(base, x)    *((uint32_t*)(base+4)) = ((uint32_t)(x)) << 16
#define DAC_GET_CLK_DIV(base)       (*((uint32_t*)(base+4)) >> 16)

#define DAC_GET_AVAILABLE(base)     (*((uint32_t*)(base+4)) & 0x00ff)

#endif