/*
  File: uart.h

  Altera JTAG UART driver
*/


#ifndef _UART_H_
#define _UART_H_

#include <stdint.h>
#include "system.h"


int  uart_avail(void);
char uart_getc(void);
void uart_putc(char c);


#endif