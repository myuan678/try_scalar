# to communicate with the host
# check riscv-software-src/riscv-tests
.section .tohost, "aw", @progbits

.align 6
.globl tohost
tohost: .dword 0

.align 6
.globl fromhost
fromhost: .dword 0



.section .text
.globl _start
_start:
    li x1, 4096
    sw x1, 0(x0)

