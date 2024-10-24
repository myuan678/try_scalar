.section .text
.globl _start
_start:
    li x1, 4096
    li x2, 0x80000000
    j label1
    li x3, 4096


label1:
    li x4, 4096
    sw x1, 0(x2)