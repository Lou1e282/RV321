#include "uart.h"

#define UART_TX_ADDR 0x10000000u

void uart_putc(char c) {
    volatile unsigned char *tx = (volatile unsigned char *)UART_TX_ADDR;
    *tx = (unsigned char)c;  
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s);
        s++;
    }
}
