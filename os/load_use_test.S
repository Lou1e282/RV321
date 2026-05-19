.section .text
.global _start

_start:
    addi x1, x0, 0x100      # base address: dmem[0x100 >> 2]
    addi x7, x0, 7
    sw   x7, 0(x1)          # seed memory with 7

    lw   x2, 0(x1)
    add  x3, x2, x2         # load-use: x3 = 14, requires stall
    add  x4, x3, x2         # forwarding chain: x4 = 21
    add  x5, x4, x3         # x5 = 35
    add  x6, x5, x4         # x6 = 56
    sw   x4, 4(x1)          # pass sentinel: dmem[0x104] = 21

pass:
    j pass
