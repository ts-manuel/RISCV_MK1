/*
  File: timer.h

  System timer

  memory map
  offset  | register
    0     | status
    4     | control
    8     | periohl[15:0]
   12     | periodh[31:16]
   16     | snapl[15:0]
   20     | snaph[31:16]
*/

#ifndef _TIMER_H_
#define _TIMER_H_

#include <stdint.h>
#include "system.h"

#define _TICKS_US_  (CLK_FREQ / 1000000)
#define _TICKS_MS_  (CLK_FREQ / 1000)
#define _TICKS_SEC_ (CLK_FREQ)


#define TIMER_START(base) AV_WRITE_DWORD(base+4, 0x0006)

/*
  Set timer period
*/
#define TIMER_SET_PERIOD(base, x)  {AV_WRITE_DWORD(base+8, x); AV_WRITE_DWORD(base+12, x>>16);}

/*
  Take snapshot of the current timer count
*/
#define TIMER_SNAP(base)  AV_WRITE_DWORD(base+16, 0)

/*
  Read value of the snapshot
*/
#define TIMER_READ(base)  (0xffffffff - ((AV_READ_DWORD(base+20)<<16) | AV_READ_DWORD(base+16)))

#endif