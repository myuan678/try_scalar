

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
        li x31, 0xc0000004
        
        li x30, 'H'
        sw x30, 0(x31)

        li x30, 'E'
        sw x30, 0(x31)

        li x30, 'L'
        sw x30, 0(x31)

        li x30, 'L'
        sw x30, 0(x31)

        li x30, 'O'
        sw x30, 0(x31)

        li x30, ' '
        sw x30, 0(x31)

        li x30, 'W'
        sw x30, 0(x31)

        li x30, 'O'
        sw x30, 0(x31)

        li x30, 'R'
        sw x30, 0(x31)

        li x30, 'L'
        sw x30, 0(x31)

        li x30, 'D'
        sw x30, 0(x31)

        li x30, '\n'
        sw x30, 0(x31)

        j tohost_exit # just terminate with exit code 0

# a0 exit code
tohost_exit:


        li a2, 1
        li x31, 0xc0000000
        sw a2, 0(x31)

        li a0, 0
        slli a0, a0, 1
        ori a0, a0, 1

        la t0, tohost
        sw a0, 0(t0)

        1: j 1b # wait for termination
