.section .text
.globl _start

_start:
    li x1, 4096
    li x2, 0x80000000
    sw x1, 0(x2)
