module toy_bpu_filter_predecoder #(
        parameter INST_WIDTH       = 32,
        parameter ADDR_WIDTH       = 32,
        parameter FILTER_CHANNEL   = 16,
        parameter DATA_WIDTH       = 32*8,
        parameter BPU_OFFSET_WIDTH = 3,
        parameter ALIGN_WIDTH      = 4
    )(
        input  logic                        dec_valid,
        input  logic [ADDR_WIDTH-1:0]       dec_pred_pc,
        input  logic [ADDR_WIDTH-1:0]       dec_tgt_pc,
        input  logic [BPU_OFFSET_WIDTH-1:0] dec_offset,
        input  logic                        dec_taken,
        input  logic                        dec_cext,
        input  logic                        dec_carry,
        input  logic [DATA_WIDTH-1:0]       dec_data,

        output logic [INST_WIDTH-1:0]       v_inst_predec  [FILTER_CHANNEL-1:0],
        output logic [ADDR_WIDTH-1:0]       v_inst_pc      [FILTER_CHANNEL-1:0],
        output logic [ADDR_WIDTH-1:0]       v_inst_pc_nxt  [FILTER_CHANNEL:0],
        output logic [FILTER_CHANNEL-1:0]   v_inst_en,
        output logic [FILTER_CHANNEL-1:0]   v_inst_last
    );

    logic [BPU_OFFSET_WIDTH-1:0] v_tmp_offset  [FILTER_CHANNEL/2-1:0];
    logic [INST_WIDTH-1:0]       v_tmp_predec  [FILTER_CHANNEL/2-1:0];

    assign v_inst_pc_nxt[FILTER_CHANNEL] = dec_tgt_pc;

    generate
        for(genvar i=0; i < FILTER_CHANNEL; i=i+1) begin: GEN_CHANNEL
            assign v_inst_en[i]   = dec_valid && (dec_offset >= i);
            assign v_inst_last[i] = dec_valid && (dec_offset == i);
            // for inst 32
            if(i < FILTER_CHANNEL/2) begin
                assign v_tmp_offset[i]  = (dec_pred_pc[ALIGN_WIDTH-1:0]>>2) + i;
                assign v_tmp_predec[i]  = dec_data[(i+1)*INST_WIDTH-1:i*INST_WIDTH];
                assign v_inst_predec[i] = v_tmp_predec[v_tmp_offset[i]];
                assign v_inst_pc[i]     = dec_pred_pc + (i<<2);
                assign v_inst_pc_nxt[i] = v_inst_en[i] ? (dec_pred_pc + (i<<2)) : dec_tgt_pc;
            end
            else begin
                assign v_inst_predec[i] = 32'b0;
                assign v_inst_pc[i]     = 32'b0;
                assign v_inst_pc_nxt[i] = dec_tgt_pc;
            end
        end
    endgenerate


endmodule 