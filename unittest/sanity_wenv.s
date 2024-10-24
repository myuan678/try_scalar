# to communicate with the host
# check riscv-software-src/riscv-tests
.globl _start
.section .tohost, "aw", @progbits

.align 6
.globl tohost
tohost: .dword 0

.align 6
.globl fromhost
fromhost: .dword 0

.section .text


_start:

        li x1, 4096
        li x2, 0x80000000
        sw x1, 0(x2)

        
        j tohost_exit # just terminate with exit code 0

# a0 exit code
tohost_exit:
        li a2, 0xdeadbeef

        li a0, 0
        slli a0, a0, 1
        ori a0, a0, 1

        la t0, tohost
        sw a0, 0(t0)

        1: j 1b # wait for termination
