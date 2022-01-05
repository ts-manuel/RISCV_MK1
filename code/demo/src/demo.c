/*
  File: demo.c

  Computes the first N terms of the fibonacci sequence
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include "disp7seg.h"
#include "dac.h"
#include "uart.h"

void play_audio(void);
void report_progress(int p);
void cmd_echo(char* args);
void cmd_memset(char* args);
void cmd_play(char* args);
void cmd_stop(char* args);

typedef struct {
  void (*handler)(char* args);
  char* str;
} cmd_t;

cmd_t commands[] = {
  {cmd_echo,    "echo"},
  {cmd_memset,  "memset"},
  {cmd_play,    "play"},
  {cmd_stop,    "stop"},
};


typedef struct {
  uint8_t*  ptr;
  uint32_t  size;
} mem_block_t;

#define MEM_BLOCK_COUNT 4
mem_block_t blocks[MEM_BLOCK_COUNT];


bool playing = false;
bool initialize = true;
int audio_stream = -1;
int video_stream = -1;

int main()
{
  char str_cmd[64];
  int cmd_ptr = 0;
  int cnt = 0;

  
  printf(">");
  fflush(stdout);
  while(1)
  {
    if (uart_avail())
    {
      char c = uart_getc();
      char* cmd;
      char* args;

      // If character is backspace, remove last character from buffer
      if(c == 127 || c == 8)
      {
        if (cmd_ptr > 0)
        {
          cmd_ptr--;
          uart_putc(c);
        }
      }
      // Read character if buffer is not full
      else if(cmd_ptr < sizeof(str_cmd))
      {
        // Detect line-feed or carrieg-return
        if(c == '\n' || c == '\r')
        {
          str_cmd[cmd_ptr] = '\0';
          cmd_ptr = 0;
          uart_putc('\n');

          // Remove spaces
          cmd = str_cmd;
          while (*cmd == ' ' && *cmd != '\0')
            cmd++;

          // Detect end of command and ramplece space with '\0'
          args = strchr (cmd, ' ');
          if (args != NULL)
          {
            *args = '\0';
            args ++;
          }
          else
          {
            args = "";
          }

          // Match the string with the available commands
          bool found = false;
          for (int i = 0; i < sizeof(commands) / sizeof(cmd_t); i++)
          {
            if (strcmp(cmd, commands[i].str) == 0)
            {
              commands[i].handler(args);
              found = true;
              break;
            }
          }

          if (found == false && cmd[0] != '\n' && cmd[0] != '\r' && cmd[0] != '\0')
          {
            printf("%s: command not found\n", cmd);
          }

          printf(">");
          fflush(stdout);
        }
        else
        {
          str_cmd[cmd_ptr++] = c;
          uart_putc(c);
        }
      }
      // Ring the bell when the buffer if full
      else
      {
        uart_putc('\a');
      }
    }

    // Play audio
    play_audio();

    // Write to LEDs
    if (((cnt++) & 0xffff) == 0)
      ALT_PIO_WRITE(_ALT_PIO_LEDS, cnt >> 16);
  }
}


void cmd_echo(char* args)
{
  printf("%s\n", args);
}

uint8_t to_hex(char c)
{
  if (c <= '9')
    return c - '0';
  else if (c == 'a' || c == 'A')
    return 0xa;
  else if (c == 'b' || c == 'B')
    return 0xb;
  else if (c == 'c' || c == 'C')
    return 0xc;
  else if (c == 'd' || c == 'D')
    return 0xd;
  else if (c == 'e' || c == 'E')
    return 0xe;
  else if (c == 'f' || c == 'F')
    return 0xf;
  else
    return 0;
}

void cmd_memset(char* args)
{
  uint8_t mem_block_id = 0;
  uint32_t size = 0;
  char* pch;
  bool parsing_ok = true;

  pch = strtok (args,"-");
  while (pch != NULL)
  {
    switch (pch[0])
    {
      case 'd': // Destination blobk ID
        sscanf(pch+2, "%d", &mem_block_id);
        break;

      case 's': // Size
        sscanf(pch+2, "%d", &size);
        break;

      default:
        printf("memset: unrecognized operand '%s'\n", pch);
        parsing_ok = false;
        break;
    }

    pch = strtok (NULL, "-");
  }

  if (parsing_ok && size > 0)
  {
    printf("Reading %d bytes to memblock %d\n", size, mem_block_id);

    if (mem_block_id > MEM_BLOCK_COUNT)
    {
      printf("Memblock ID: %d out of range, max is %d\n", mem_block_id, MEM_BLOCK_COUNT);
      return;
    }

    // Allocate memory
    free(blocks[mem_block_id].ptr);
    blocks[mem_block_id].ptr = (uint8_t*)malloc(size);
    blocks[mem_block_id].size = size;
    if(blocks[mem_block_id].ptr == NULL)
    {
      printf("Unable to allocate memory, malloc() returned NULL\n", mem_block_id, MEM_BLOCK_COUNT);
      return;
    }

    //Read bytes
    for (int i = 0; i < size; i++)
    {
      /*if ((i & 0xffff) == 0)
      {
        report_progress((100*i)/size);
      }*/
      disp7seg_write_hex(i);

      uint8_t byte;
      byte  = to_hex(uart_getc()) * 16;
      byte += to_hex(uart_getc());

      blocks[mem_block_id].ptr[i] = byte;
    }

    //report_progress(100);
  }
}


void report_progress(int p)
{
  static int state = 0;

  char str_cln[]  = "                \r";
  char str_msg1[] = "Progress: [";
  char str_msg2[] = "%]";
  int cnt, dec, uni;

  if (state == 0 || p == 100)
  {
    for (char* c = str_cln; *c != '\0'; c++)
      AV_WRITE_BYTE(_ALT_JTAG_UART, *c);

    state = 1;
  }
  else if (state == 1 || p == 100)
  {
    for (char* c = str_msg1; *c != '\0'; c++)
      AV_WRITE_BYTE(_ALT_JTAG_UART, *c);

    state = 2;
  }
  else if (state == 2 || p == 100)
  {
    uni = p % 10;
    cnt == 0 ? ' ' : cnt + '0';
    p /= 10;
    dec = p % 10;
    dec == 0 ? ' ' : dec + '0';
    p /= 10;
    cnt = p + '0';

    AV_WRITE_BYTE(_ALT_JTAG_UART, cnt);
    AV_WRITE_BYTE(_ALT_JTAG_UART, dec);
    AV_WRITE_BYTE(_ALT_JTAG_UART, uni);

    for (char* c = str_msg2; *c != '\0'; c++)
      AV_WRITE_BYTE(_ALT_JTAG_UART, *c);

    state = 0;
  }
  else
  {
    state = 0;
  }
}



void cmd_play(char* args)
{
  char* pch;
  bool parsing_ok = true;

  audio_stream = -1;
  video_stream = -1;

  pch = strtok (args,"-");
  while (pch != NULL)
  {
    switch (pch[0])
    {
      case 'a': // Destination blobk ID
        sscanf(pch+2, "%d", &audio_stream);
        break;

      case 'v': // Size
        sscanf(pch+2, "%d", &video_stream);
        break;

      default:
        printf("play: unrecognized operand '%s'\n", pch);
        parsing_ok = false;
        break;
    }

    pch = strtok (NULL, "-");
  }

  if (parsing_ok)
  {
    printf("Playng: audio source=%d, video source=%d\n", audio_stream, video_stream);
    playing = true;
    initialize = true;

    play_audio();
  }
}


void cmd_stop(char* args)
{
  playing = false;
  initialize = true;
}


void play_audio(void)
{
  static uint8_t* audio_ptr = NULL;
  static uint16_t num_channels;
  static uint32_t sample_rate;
  static uint16_t bits_per_sample;

  if (playing && audio_stream >= 0)
  {
    if (initialize == true)
    {
      initialize = false;
      audio_ptr = blocks[audio_stream].ptr;

      num_channels  = (uint16_t)audio_ptr[23] << 8;
      num_channels |= (uint16_t)audio_ptr[22] << 0;
      sample_rate   = (uint32_t)audio_ptr[27] << 24;
      sample_rate  |= (uint32_t)audio_ptr[26] << 16;
      sample_rate  |= (uint32_t)audio_ptr[25] << 8;
      sample_rate  |= (uint32_t)audio_ptr[24] << 0;
      bits_per_sample  = (uint16_t)audio_ptr[35] << 8;
      bits_per_sample |= (uint16_t)audio_ptr[34] << 0;

      audio_ptr += 40;

      printf("num: %d, samplerate: %d, bits: %d\n", num_channels, sample_rate, bits_per_sample);

      // Set DAC sample rate
      DAC_SET_CLK_DIV(_AV_STEREO_DAC, CLK_FREQ/sample_rate);
    }
    else if (audio_ptr > (blocks[audio_stream].ptr + blocks[audio_stream].size))
    {
      audio_ptr = NULL;
      playing = false;
    }
    else
    {
      for (int i = 0; i < DAC_GET_AVAILABLE(_AV_STEREO_DAC); i++)
      {
        uint16_t sample_l;
        uint16_t sample_r;

        if (bits_per_sample == 8)
        {
          sample_l = (uint16_t)audio_ptr[0] << 8;
          sample_r = (uint16_t)audio_ptr[1] << 8;
        }
        else
        {
          sample_l = (((uint16_t)audio_ptr[1] << 8) | audio_ptr[0]) + 0x8000;
          sample_r = (((uint16_t)audio_ptr[3] << 8) | audio_ptr[2]) + 0x8000;
        }

        audio_ptr += num_channels * (bits_per_sample / 8);

        if (num_channels == 1)
          DAC_LR_SAMPLE(_AV_STEREO_DAC, sample_l, sample_l);
        else
          DAC_LR_SAMPLE(_AV_STEREO_DAC, sample_l, sample_r);
      }
    }
  }
}