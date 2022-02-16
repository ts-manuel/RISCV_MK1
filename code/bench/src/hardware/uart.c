/*
  File: uart.c

  Altera JTAG UART driver
*/

#include "uart.h"


static char next_char;
static bool next_char_valid = false;

int  uart_avail(void)
{
  uint32_t data;

  if (next_char_valid == true)
    return 1;

  data = READ_DWORD(_ALT_JTAG_UART);
  next_char = data & 0xff;
  next_char_valid = data & 0x8000;

  return next_char_valid;
}

char uart_getc(void)
{
  //Whait for character
  while(uart_avail() == 0);

  next_char_valid = false;

  //Return next character
  return next_char;
}

void uart_putc(char c)
{
  int avail;

  do
  {
    avail = READ_DWORD(_ALT_JTAG_UART+4) >> 16;
  } while (avail != 64);

  WRITE_BYTE(_ALT_JTAG_UART, c);
}



#if defined(__GNUC__)

int _write(int fd, char * ptr, int len)
{
  for (int i = 0; i < len; i++)
  {
    uart_putc(*(ptr++));
  }

	return len;
}

int _read(int file, char *ptr, int len)
{
  for (int i = 0; i < len; i++)
  {
    *(ptr++) = uart_getc();
  }

	return len;
}

#elif defined (__ICCARM__)
#include "LowLevelIOInterface.h"

size_t __write(int handle, const unsigned char * buffer, size_t size)
{
  for (size_t i = 0; i < size; i++)
  {
    uart_putc(*(buffer++));
  }

	return size;
}

#elif defined (__CC_ARM)

int fputc(int ch, FILE *f)
{

  uart_putc(ch);

	return ch;
}

#endif