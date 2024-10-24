#include "svdpi.h"
#include "riscv_disas.h"

// void disasm_inst(char *buf, size_t buflen, rv_isa isa, uint64_t pc, rv_inst inst)
// {
//     rv_decode dec = { .pc = pc, .inst = inst };
//     decode_inst_opcode(&dec, isa);
//     decode_inst_operands(&dec);
//     decode_inst_decompress(&dec, isa);
//     decode_inst_lift_pseudo(&dec);
//     decode_inst_format(buf, buflen, 32, &dec);
// }

void toy_scalar_disasm(char** buf, int unsigned pc, int unsigned inst) {
    static char *char_buf = NULL;
    if(char_buf == NULL)
        char_buf = malloc(128);
    disasm_inst(char_buf, 128, rv32, pc, inst);
    *buf = char_buf;
}