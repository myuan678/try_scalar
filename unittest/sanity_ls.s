
# to communicate with the host
# check riscv-software-src/riscv-tests
.section .tohost, "aw", @progbits
.globl _start

.align 6
.globl tohost
tohost: .dword 0

.align 6
.globl fromhost
fromhost: .dword 0

.section .text



_start:
        li x1, 4096
        li x2, 0x81000000
        sw x1, 0(x2)
        lw x3, 0(x2)
        sw x3, 4(x2)
        
        li x2, 0x80000000
        sw x1, 0(x2)

        j tohost_exit



# a0 exit code
tohost_exit:
        li a2, 0xdeadbeef

        li a0, 0
        slli a0, a0, 1
        ori a0, a0, 1

        la t0, tohost
        sw a0, 0(t0)

        1: j 1b # wait for termination
