/*
  File: hpc.h

  Altera JTAG UART driver
*/


#ifndef _HPC_H_
#define _HPC_H_

#include <stdint.h>
#include <stdbool.h>
#include "system.h"

#define HPC_START(base)     WRITE_DWORD(base, 0x00000001)
#define HPC_STOP(base)      WRITE_DWORD(base, 0x00000002)
#define HPC_CLEAR(base)     WRITE_DWORD(base, 0x00000004)
#define HPC_SNAPSHOT(base)  WRITE_DWORD(base, 0x00000008)

#define HPC_GET_CLOCK_CNT(base) ((uint64_t)READ_DWORD(base+ 4) | ((uint64_t)READ_DWORD(base+ 8)<<32))
#define HPC_GET_INSTR_CNT(base) ((uint64_t)READ_DWORD(base+12) | ((uint64_t)READ_DWORD(base+16)<<32))
#define HPC_GET_FETCH_CNT(base) ((uint64_t)READ_DWORD(base+20) | ((uint64_t)READ_DWORD(base+24)<<32))
#define HPC_GET_EXECU_CNT(base) ((uint64_t)READ_DWORD(base+28) | ((uint64_t)READ_DWORD(base+32)<<32))
#define HPC_GET_MEMRY_CNT(base) ((uint64_t)READ_DWORD(base+36) | ((uint64_t)READ_DWORD(base+40)<<32))

#endif