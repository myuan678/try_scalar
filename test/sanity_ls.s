.section .text
.globl _start
_start:
    li x1, 4096
    sw x1, 0(x0)
    lw x2, 0(x0)
    sw x2, 4(x0)
    j label1
    li x3, 4096


label1:
    li x4, 4096