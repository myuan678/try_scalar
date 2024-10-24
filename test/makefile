
all:
	riscv64-unknown-elf-gcc -Wl,-Map=sanity_imm.map -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,-T riscv.ld -Ttext=0 -o sanity_imm.elf sanity_imm.s 
	riscv64-unknown-elf-objcopy -O binary sanity_imm.elf sanity_imm.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 sanity_imm.bin > sanity_imm.asm
	hexdump -v -e '"%08x\n"' sanity_imm.bin > sanity_imm.hex


	# riscv64-unknown-elf-gcc -c -march=rv32i -mabi=ilp32 sanity_imm.s -o sanity_imm.o
	# riscv64-unknown-elf-ld -m elf32lriscv sanity_imm.o -o sanity_imm.elf

test:
	riscv64-unknown-elf-as -o sanity_imm.o sanity_imm.s 
	riscv64-unknown-elf-ld -Map=test.map -T riscv.ld -o sanity_imm.elf sanity_imm.o
	riscv64-unknown-elf-objcopy -O binary sanity_imm.elf sanity_imm.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 sanity_imm.bin > sanity_imm.asm
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv64 sanity_imm.bin > sanity_imm.asm.64
	hexdump -v -e '"%08x\n"' sanity_imm.bin > sanity_imm.hex


ls:
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0 -o sanity_ls.elf sanity_ls.s
	riscv64-unknown-elf-objcopy -O binary sanity_ls.elf sanity_ls.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 sanity_ls.bin > sanity_ls.asm
	hexdump -v -e '"%08x\n"' sanity_ls.bin > sanity_ls.hex

jal:
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0 -o sanity_jal.elf sanity_jal.s
	riscv64-unknown-elf-objcopy -O binary sanity_jal.elf sanity_jal.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 sanity_jal.bin > sanity_jal.asm
	hexdump -v -e '"%08x\n"' sanity_jal.bin > sanity_jal.hex

wenv:
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Ttext=0 -o sanity_wenv.elf sanity_wenv.s
	riscv64-unknown-elf-objcopy -O binary sanity_wenv.elf sanity_wenv.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 sanity_wenv.bin > sanity_wenv.asm
	hexdump -v -e '"%08x\n"' sanity_wenv.bin > sanity_wenv.hex