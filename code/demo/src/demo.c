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
#include "video.h"
#include "timer.h"

void play_audio(void);
void play_video(void);
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


bool playing_audio = false;
bool playing_video = false;
bool initialize_audio = true;
bool initialize_video = true;
int audio_stream = -1;
int video_stream = -1;

int main()
{
  char str_cmd[64];
  int cmd_ptr = 0;
  int cnt = 0;
  uint32_t t0, t1, t2;
  
  TIMER_SET_PERIOD(_AV_TIMER, 0xffffffff);
  TIMER_START(_AV_TIMER);
  

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

    // Play audio and video
    //TIMER_SNAP(_AV_TIMER);
    //t0 = TIMER_READ(_AV_TIMER);

    play_audio();

    //TIMER_SNAP(_AV_TIMER);
    //t1 = TIMER_READ(_AV_TIMER);

    play_video();

    //TIMER_SNAP(_AV_TIMER);
    //t2 = TIMER_READ(_AV_TIMER);

    //Write time to 7-seg
    //uint32_t audio_ms = (t1 - t0)/_TICKS_US_;
    //uint32_t video_ms = (t2 - t1)/_TICKS_US_;
    //disp7seg_write_hex((audio_ms << 16) | video_ms);

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
      if ((i & 0xffff) == 0)
      {
        //report_progress((100*i)/size);
      }
      disp7seg_write_hex(i);

      uint8_t byte;
      byte  = to_hex(uart_getc()) * 16;
      byte += to_hex(uart_getc());

      blocks[mem_block_id].ptr[i] = byte;
    }

    report_progress(100);
    printf("\n");
  }
}


void report_progress(int p)
{
  char str_cln[]  = "                \r";
  char str_msg1[] = "Progress: [";
  char str_msg2[] = "%]";
  int cnt, dec, uni, tmp;

  for (char* c = str_cln; *c != '\0'; c++)
    AV_WRITE_BYTE(_ALT_JTAG_UART, *c);

  for (char* c = str_msg1; *c != '\0'; c++)
      AV_WRITE_BYTE(_ALT_JTAG_UART, *c);

  uni = p % 10 + '0';
  tmp = p / 10;
  dec = tmp % 10;
  dec = (p < 10) ? ' ' : dec + '0';
  tmp /= 10;
  cnt = (p < 100) ? ' ' : tmp + '0';

  AV_WRITE_BYTE(_ALT_JTAG_UART, cnt);
  AV_WRITE_BYTE(_ALT_JTAG_UART, dec);
  AV_WRITE_BYTE(_ALT_JTAG_UART, uni);

  for (char* c = str_msg2; *c != '\0'; c++)
    AV_WRITE_BYTE(_ALT_JTAG_UART, *c);
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
    playing_audio = true;
    playing_video = true;
    initialize_audio = true;
    initialize_video = true;

    play_audio();
    play_video();
  }
}


void cmd_stop(char* args)
{
  playing_audio = false;
  playing_video = false;
  initialize_audio = true;
  initialize_video = true;
}


void play_audio(void)
{
  static uint8_t* audio_ptr = NULL;
  static uint16_t num_channels;
  static uint32_t sample_rate;
  static uint16_t bits_per_sample;

  if (playing_audio && audio_stream >= 0)
  {
    if (initialize_audio == true)
    {
      initialize_audio = false;
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
      playing_audio = false;
    }
    else
    {
      int available = DAC_GET_AVAILABLE(_AV_STEREO_DAC);

      for (int i = 0; i < available; i++)
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

#define h_div   2
#define v_div   2
#define width   (640 / h_div)
#define height  (480 / v_div)

void play_video(void)
{
  static int pixel_count;
  static int decod_count;
  static uint32_t  video_buffer[2][640*480];
  static uint32_t* video_ptr = NULL;
  static uint32_t* decod_ptr = NULL;
  static uint8_t*  decod_src_ptr = NULL;
  static int active_video_buffer;
  static bool v_sync_wait = true;
  static int frame_number;

  if (playing_video && video_stream >= 0)
  {
    if (initialize_video == true)
    {
      initialize_video = false;

      video_ptr = video_buffer[0];
      decod_ptr = video_buffer[1];
      decod_src_ptr = blocks[video_stream].ptr;
      active_video_buffer = 0;
      frame_number = 0;

      printf("Video initialized\n");

      // Initialize clocks
      VIDEO_SET_CLK(_AV_VIDEO_GEN, 3, h_div, v_div);
    }
    else if (decod_src_ptr > (blocks[video_stream].ptr + blocks[video_stream].size))
    {
      decod_src_ptr = NULL;
      playing_video = false;
    }
    else
    {
      // Transfer video buffer
      if (pixel_count >= width * height)
      {
        // swap buffers every 4 frames
        if(frame_number++ >= 3)
        {
          decod_ptr = video_buffer[active_video_buffer];
          active_video_buffer = (active_video_buffer+1) % 2;
          decod_count   = 0;
          frame_number  = 0;
        }

        video_ptr = video_buffer[active_video_buffer];
        pixel_count = 0;
        
        v_sync_wait = true;
      }

      uint32_t status = VIDEO_GET_STATUS(_AV_VIDEO_GEN);
      int fifo_avail = status & 0xffff;
      if(v_sync_wait && (status & 0x00010000))
      {
        VIDEO_CLR_FIFO(_AV_VIDEO_GEN);
        v_sync_wait = false;
        fifo_avail  = 64;
      }

      if(!v_sync_wait)
      {
        if(fifo_avail >= 16)
        {
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          pixel_count += 32*16;
          fifo_avail -= 16;
        }

        if(fifo_avail >= 8)
        {
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          pixel_count += 32*8;
          fifo_avail -= 8;
        }

        if(fifo_avail >= 4)
        {
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          VIDEO_WRITE_FIFO(_AV_VIDEO_GEN, *(video_ptr++));
          pixel_count += 32*4;
          fifo_avail -= 4;
        }
      }


      // Video decoding
      if (decod_count < width*height)
      {
        //Decode one line
        int x = 0;
        bool black = true;
        *decod_ptr = 0x00000000;

        while (x < width)
        {
          int bits = *decod_src_ptr++;

          for (int i = 0; i < bits; i++)
          {
            if(!black)
            {
              *decod_ptr |= 0x00000001 << (x % 32);
            }
            
            if ((x + 1) % 32 == 0)
            {
              *(++decod_ptr) = 0x00000000;
            }

            x++;
          }

          black = !black;
        }

        decod_count += width;
      }
    }
  }
}