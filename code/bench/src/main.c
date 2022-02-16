/*
  File: main.c

  RISC-V JPEG Decoder benchmark


*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include "jpeg/decoder.h"
#include "hardware/hpc.h"


#define _TEST_COUNT 3
#define _MAX_WIDTH  320
#define _MAX_HEIGHT 240

typedef struct
{
  const uint8_t*  data;
  const char*     name;
} image_t;

extern uint8_t lena_320_240_4k[];
extern uint8_t lena_320_240_8k[];
extern uint8_t lena_320_240_16k[];
image_t test_images[_TEST_COUNT] = 
{
  {lena_320_240_4k,  "jpg 320x240 4k"},
  {lena_320_240_8k,  "jpg 320x240 8k"},
  {lena_320_240_16k, "jpg 320x240 16k"}
};


const char* info_str =
"++++++++++++++++++++++++++++++++\n"
" RISC-V JPEG Decoding benchmark \n"
"++++++++++++++++++++++++++++++++\n";

int main()
{
  JPG_t jpg;
  uint8_t frame_buffer[_MAX_WIDTH*_MAX_HEIGHT*3];
 
  printf("%s\n", info_str);

  for (int i = 0; i < _TEST_COUNT; i++)
  {
    printf("Decoding of: %s\n", test_images[i].name);

    //Reset hardware counters
    HPC_CLEAR(_HPC_ADDR_);
    HPC_START(_HPC_ADDR_);

    //Perform JPEG decoding
    if(JPG_decode(&jpg, (uint8_t*)test_images[i].data, frame_buffer))
    {
      printf("ERROR: decoding failed\n");
      break;
    }

    //Read hardware counters
    HPC_SNAPSHOT(_HPC_ADDR_);
    uint64_t clock_cnt = HPC_GET_CLOCK_CNT(_HPC_ADDR_);
    uint64_t instr_cnt = HPC_GET_INSTR_CNT(_HPC_ADDR_);
    uint64_t fetch_cnt = HPC_GET_FETCH_CNT(_HPC_ADDR_);
    uint64_t execu_cnt = HPC_GET_EXECU_CNT(_HPC_ADDR_);
    uint64_t memry_cnt = HPC_GET_MEMRY_CNT(_HPC_ADDR_);

    //Print results
    double seconds = (double)clock_cnt / (double)_CLK_FREQ;
    double ipc = (double)instr_cnt / (double)clock_cnt;
    double fetch = 100.f * (double)fetch_cnt / (double)clock_cnt;
    double execu = 100.f * (double)execu_cnt / (double)clock_cnt;
    double memry = 100.f * (double)memry_cnt / (double)clock_cnt;

    printf("Elapsed time: %fs\n", seconds);
    printf("Computed IPC: %f\n", ipc);
    printf("CPU Fetch:... %f%%\n", fetch);
    printf("CPU Execute:. %f%%\n", execu);
    printf("CPU Memory:.. %f%%\n", memry);
    printf("\n");
  }

  //Halt processor
  while(1);
}


void dump(uint32_t start, uint32_t size)
{
  uint8_t* ptr = (uint8_t*)start;
  uint8_t* end = ptr + size;

  while (ptr < end)
  {
    printf("%08x: ", (uint32_t)ptr);

    for (int i = 0; i < 16; i++)
      printf("%02x ", ptr[i]);

    printf(" ");

    for (int i = 0; i < 16; i++)
      printf("%c ", isprint(ptr[i]) ? ptr[i] : '.');

    printf("\n");
    ptr += 16;
  }
}