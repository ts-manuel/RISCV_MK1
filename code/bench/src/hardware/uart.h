/*
  File: uart.h

  Altera JTAG UART driver
*/


#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>
#include <stdbool.h>
#include "system.h"

/*
  Returns number of bytes available in the RX FIFO
*/
int  uart_avail(void);

/*
  Reads one character
*/
char uart_getc(void);

/*
  Writes one character
*/
void uart_putc(char c);


#endif