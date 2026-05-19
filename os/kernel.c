#include "uart.h"

void kernel_main(void) {

    // uart
    uart_puts("Hello RV32I\n");

    while (1) {
    }
}
