

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
        li x31, 0x81000000
        sw x1, 0(x31)

        li a2, 0xdeadbeef
        j tohost_exit # just terminate with exit code 0

# a0 exit code
tohost_exit:


        li x31, 0xc0000000
        sw a2, 0(x31)

        li a0, 0
        slli a0, a0, 1
        ori a0, a0, 1

        la t0, tohost
        sw a0, 0(t0)

        1: j 1b # wait for termination
