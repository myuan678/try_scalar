module toy_bpu_filter
    import toy_pack::*;
    #(
        localparam  int unsigned FETCH_DATA_WIDTH = ADDR_WIDTH*FETCH_WRITE_CHANNEL
    )(
        input logic                                  clk,
        input logic                                  rst_n,

        // BTFIFO ==========================================
        output logic                                 btfifo_rdy,
        input  logic                                 btfifo_vld,
        input  bpu_pkg                               btfifo_pld,

        // ROB =============================================
        output logic                                 rob_rdy,
        input  logic                                 rob_vld,
        input  logic [FETCH_DATA_WIDTH-1:0]          rob_pld,

        // RAS =============================================
        output logic                                 ras_req_vld,
        output ras_pkg                               ras_req_pld,

        // Fetch Queue =====================================
        input  logic                                 fetch_queue_rdy,
        output logic                                 fetch_queue_vld,
        output fetch_queue_pkg                       fetch_queue_pld [FILTER_CHANNEL-1:0],
        output logic           [FILTER_CHANNEL-1:0]  fetch_queue_en,

        // FE Controller ===================================
        input  logic                                 fe_ctrl_be_chgflw,
        input  logic                                 fe_ctrl_ras_chgflw,
        input  bpu_pkg                               fe_ctrl_ras_pld,
        output logic                                 fe_ctrl_enqueue,
        output logic   [ADDR_WIDTH-1:0]              fe_ctrl_enqueue_pld
    );

    logic [INST_WIDTH-1:0]              v_inst_predec      [FILTER_CHANNEL-1:0];
    logic [ADDR_WIDTH-1:0]              v_inst_pc          [FILTER_CHANNEL-1:0];
    logic [ADDR_WIDTH-1:0]              v_inst_pc_nxt      [FILTER_CHANNEL:0];
    logic [FILTER_CHANNEL-1:0]          v_inst_en;
    logic [FILTER_CHANNEL-1:0]          v_inst_last;
    logic                               is_call;
    logic                               is_ret;

    logic [ADDR_WIDTH-1:0]              real_tgt_pc;

    logic                               dec_valid;
    logic [ADDR_WIDTH-1:0]              dec_pred_pc;
    logic [ADDR_WIDTH-1:0]              dec_tgt_pc;
    logic [BPU_OFFSET_WIDTH-1:0]        dec_offset;
    logic                               dec_taken;
    logic                               dec_cext;
    logic                               dec_carry;
    logic [DATA_WIDTH-1:0]              dec_data;

    logic [INST_WIDTH-1:0]              last_inst;


    // to other module
    assign btfifo_rdy            = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;
    assign rob_rdy               = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;

    assign ras_req_vld           = rob_vld && btfifo_vld && fetch_queue_rdy;
    assign ras_req_pld.inst_type = {is_ret, is_call};
    assign ras_req_pld.is_cext   = btfifo_pld.is_cext;
    assign ras_req_pld.carry     = btfifo_pld.carry;
    assign ras_req_pld.offset    = btfifo_pld.offset;
    assign ras_req_pld.pred_pc   = btfifo_pld.pred_pc;
    assign ras_req_pld.pc        = btfifo_pld.pred_pc + (btfifo_pld.offset<<2);
    assign ras_req_pld.tgt_pc    = btfifo_pld.tgt_pc;
    assign ras_req_pld.taken     = btfifo_pld.taken;

    assign fetch_queue_vld       = rob_vld && btfifo_vld && ~fe_ctrl_be_chgflw;
    assign fetch_queue_en        = v_inst_en;
    generate
        for (genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_FQ
            assign fetch_queue_pld[i].inst                  = v_inst_predec[i];
            assign fetch_queue_pld[i].bypass.is_call        = is_call;
            assign fetch_queue_pld[i].bypass.is_ret         = is_ret;
            assign fetch_queue_pld[i].bypass.pc             = v_inst_pc[i];
            assign fetch_queue_pld[i].bypass.is_last        = v_inst_last[i];
            assign fetch_queue_pld[i].bypass.bypass.carry   = btfifo_pld.is_cext;
            assign fetch_queue_pld[i].bypass.bypass.is_cext = btfifo_pld.carry;
            assign fetch_queue_pld[i].bypass.bypass.pred_pc = btfifo_pld.pred_pc;
            assign fetch_queue_pld[i].bypass.bypass.taken   = btfifo_pld.taken;
            assign fetch_queue_pld[i].bypass.bypass.tgt_pc  = v_inst_pc_nxt[i+1];
            assign fetch_queue_pld[i].bypass.bypass.offset  = btfifo_pld.offset;
        end
    endgenerate

    assign fe_ctrl_enqueue       = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;
    assign fe_ctrl_enqueue_pld   = btfifo_pld.pred_pc;

    // pre-decode
    assign real_tgt_pc           = fe_ctrl_ras_chgflw ? fe_ctrl_ras_pld.tgt_pc : btfifo_pld.tgt_pc;

    assign dec_valid             = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;
    assign dec_pred_pc           = btfifo_pld.pred_pc;
    assign dec_tgt_pc            = real_tgt_pc;
    assign dec_offset            = btfifo_pld.offset;
    assign dec_taken             = btfifo_pld.taken;
    assign dec_cext              = btfifo_pld.is_cext;
    assign dec_carry             = btfifo_pld.carry;
    assign dec_data              = rob_pld;

    toy_bpu_filter_predecoder #(
        .INST_WIDTH      (INST_WIDTH            ),
        .ADDR_WIDTH      (ADDR_WIDTH            ),
        .FILTER_CHANNEL  (FILTER_CHANNEL        ),
        .DATA_WIDTH      (FETCH_DATA_WIDTH      ),
        .BPU_OFFSET_WIDTH(BPU_OFFSET_WIDTH      ),
        .ALIGN_WIDTH     (ALIGN_WIDTH           )
    ) u_predecoder (
        .dec_valid    (dec_valid                ),
        .dec_pred_pc  (dec_pred_pc              ),
        .dec_tgt_pc   (dec_tgt_pc               ),
        .dec_offset   (dec_offset               ),
        .dec_taken    (dec_taken                ),
        .dec_cext     (dec_cext                 ),
        .dec_carry    (dec_carry                ),
        .dec_data     (dec_data                 ),
        .v_inst_predec(v_inst_predec            ),
        .v_inst_pc    (v_inst_pc                ),
        .v_inst_pc_nxt(v_inst_pc_nxt            ),
        .v_inst_en    (v_inst_en                ),
        .v_inst_last  (v_inst_last              )
    );


    // to ras
    // call
    // 1. jalr: rd == x1 or rd == x5;
    // 2. jal : rd == x1 or rd == x5;
    // 3. c.jalr
    // ret
    // 1. jalr: rs1 == x1 or rs1 == x5 and rs1!=rd;
    // 2. c.jr: rs1 ==x1 or rs1 == x5;
    // 3. c.jalr: rs1 == x5

    assign last_inst = v_inst_predec[dec_offset];

    assign is_call = (({last_inst[14:12],last_inst[6:0]} == 10'b000_1100111) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101))) //jalr
    || ((last_inst[6:0] == 7'b1101111) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101)))                                       //jal
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1001_00000_10) && (last_inst[11:7] != 5'b0));                                                   //c.jalr

    assign is_ret  = (({last_inst[14:12],last_inst[6:0]} == 10'b000_1100111) && (last_inst[11:7] != last_inst[19:15]) && ((last_inst[19:15] == 5'b00001) || (last_inst[19:15] == 5'b00101)) && (last_inst[31:20] == 12'b0)) //jalr
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1000_00000_10) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101)) && (last_inst[11:7] != 5'b00000))                                                      //jalr
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1001_00000_10) && (last_inst[11:7] == 5'b00101));                                                                                                                         //c.jalr

endmodule 