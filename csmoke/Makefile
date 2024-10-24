
all:
	riscv64-unknown-elf-gcc -Wl,-Map=main.map -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,-T riscv.ld -Ttext=0 -o main.elf main.c
	#riscv64-unknown-elf-objcopy -O binary sanity_imm.elf sanity_imm.bin
	riscv64-unknown-elf-objdump -D -m riscv:rv32 main.elf > sanity_imm.asm
	#hexdump -v -e '"%08x\n"' sanity_imm.bin > sanity_imm.hex
