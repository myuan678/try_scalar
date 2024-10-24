OUTPUT_ARCH("riscv")

ENTRY(_start)

MEMORY
{
    ITCM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x40000000
    DTCM (rwx) : ORIGIN = 0xa0000000, LENGTH = 0x40000000
}

SECTIONS
{
    .dtcm : ALIGN(0x1000)
    {
        *(.tohost)
    } > DTCM

    .itcm : ALIGN(0x1000)
    {
        *(.text)
    } > ITCM
}