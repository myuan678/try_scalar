module toy_bpu_bpdec
    import toy_pack::*;
    (
        input logic                                             clk,
        input logic                                             rst_n,

        // BP1 =========================================
        input logic                                             l0btb_vld,
        input bpu_pkg                                           l0btb_pld,

        // BP2 =========================================
        input  logic                                            tage_vld,
        input  tage_pkg                                         tage_pld,
        input  logic                                            tage_w_vld,
        output logic                                            tage_w_rdy,
        output tage_entry_buffer_pkg                            tage_w_pld,

        input  logic                                            btb_vld,
        input  btb_pkg                                          btb_pld,
        output btb_entry_buffer_pkg                             btb_bypass_pld [ENTRY_BUFFER_NUM-1:0],
        output logic                [ENTRY_BUFFER_PTR_WIDTH:0]  btb_bypass_ptr,
        output logic                [ENTRY_BUFFER_NUM-1:0]      btb_bypass_ena,
        input  logic                                            btb_w_vld,
        output logic                                            btb_w_rdy,
        output btb_entry_buffer_pkg                             btb_w_pld,

        // GHR ================================
        output logic                                            ghr_vld,
        output logic                                            ghr_taken,

        // Branch Target FIFO ==========================
        output   logic                                          fifo_bp2_vld,
        output   logic                                          fifo_bp2_chgflw_vld,
        output   bpu_pkg                                        fifo_bp2_chgflw_pld,

        // ROB ================================
        output   logic                                          rob_bp2_vld,
        output   logic                                          rob_bp2_flush,

        // FE Controller ===============================
        input   logic                                           fe_ctrl_be_flush,
        input   logic                                           fe_ctrl_be_chgflw_vld,
        input   bpu_update_pkg                                  fe_ctrl_be_chgflw_pld,
        input   logic                                           fe_ctrl_ras_flush,
        input   logic                                           fe_ctrl_ras_enqueue_vld,
        output  logic                                           fe_ctrl_entry_buffer_rdy,
        output  logic                                           fe_ctrl_bp2_chgflw_vld,
        output  bpu_pkg                                         fe_ctrl_bp2_chgflw_pld

    );

    localparam BTB_OFFSET_WIDTH = BPU_OFFSET_WIDTH + 2;

    // pipeline
    logic                                                       l0btb_vld_s0;
    bpu_pkg                                                     l0btb_pld_s0;
    logic                                                       l0btb_vld_s1;
    bpu_pkg                                                     l0btb_pld_s1;
    logic                                                       tage_vld_s1;
    tage_pkg                                                    tage_pld_s1;
    logic                                                       btb_vld_s1;
    btb_pkg                                                     btb_pld_s1;

    // btb
    logic                [BTB_WAY_NUM-1:0]                      way_vld;
    logic                [BTB_WAY_NUM-1:0]                      way_hit;
    logic                [ADDR_WIDTH+BTB_OFFSET_WIDTH-1:0]      v_entry_way_pred  [BTB_WAY_NUM-1:0];
    logic                [ADDR_WIDTH+BTB_OFFSET_WIDTH-1:0]      entry_way_pred;
    logic                [TAGE_TABLE_NUM:0]                     entry_hit;
    // tage
    logic                [TAGE_TABLE_NUM:0]                     prvd_hit_onehot   [1:0];
    logic                [$clog2(TAGE_TABLE_NUM):0]             prvd_hit_index    [1:0];
    logic                [1:0]                                  prvd_hit ;
    logic                                                       prvd_pred_res;
    logic                                                       alt_pred_res;
    logic                                                       pred_res;
    logic                                                       is_new_entry;
    tage_tx_field_pkg                                           prvd_entry_pld;
    tage_tx_field_pkg                                           alt_entry_pld;
    tage_tx_field_pkg                                           tx_entry_pld      [TAGE_TABLE_NUM-1:0];
    // compare
    logic                                                       bp2_tgt_pc_hit;
    logic                                                       bp2_offset_hit;
    logic                [ADDR_WIDTH-1:0]                       bp2_cmp_tgt_pc;
    logic                [BPU_OFFSET_WIDTH-1:0]                 bp2_cmp_offset;
    logic                                                       bp2_cmp_is_cext;
    logic                                                       bp2_cmp_carry;
    logic                [ADDR_WIDTH-1:0]                       bp2_tgt_pc;
    logic                [BPU_OFFSET_WIDTH-1:0]                 bp2_offset;
    logic                                                       bp2_is_cext;
    logic                                                       bp2_carry;
    logic                                                       bp2_chgflw_vld_s1;
    bpu_pkg                                                     bp2_chgflw_pld_s1;

    // alignment
    logic                [ADDR_WIDTH-1 :0]                      non_align_tgt_pc;
    logic                [ADDR_WIDTH-1 :0]                      non_align_offset;
    logic                                                       non_align_cext;
    logic                                                       non_align_carry;
    logic                                                       need_align;

    logic                                                       entry_vld_s0;
    logic                                                       entry_rdy_s0;
    logic                                                       entry_vld_s1;
    entry_buffer_pkg                                            entry_pld_s1;
    logic                                                       entry_update_vld;
    bpu_update_pkg                                              entry_update_pld;
    logic                                                       entry_vld_m;
    logic                                                       entry_rdy_m;
    entry_buffer_pkg                                            entry_pld_m;

    //============================================================
    // Interface
    //============================================================
    assign tage_w_rdy                          = entry_vld_m;
    assign tage_w_pld                          = entry_pld_m.tage_entry;
    assign btb_w_rdy                           = entry_vld_m;
    assign btb_w_pld                           = entry_pld_m.btb_entry;

    assign ghr_vld                             = entry_vld_s1;
    assign ghr_taken                           = pred_res;

    assign rob_bp2_vld                         = l0btb_vld_s0;
    assign rob_bp2_flush                       = bp2_chgflw_vld_s1;

    assign fifo_bp2_vld                        = tage_vld_s1 && btb_vld_s1;
    assign fifo_bp2_chgflw_vld                 = 1'b0;
    assign fifo_bp2_chgflw_pld.taken           = pred_res;
    assign fifo_bp2_chgflw_pld.pred_pc         = tage_pld_s1.pred_pc;
    assign fifo_bp2_chgflw_pld.offset          = bp2_offset;
    assign fifo_bp2_chgflw_pld.is_cext         = bp2_is_cext;
    assign fifo_bp2_chgflw_pld.carry           = bp2_carry;
    assign fifo_bp2_chgflw_pld.tgt_pc          = bp2_tgt_pc;

    assign fe_ctrl_bp2_chgflw_vld              = bp2_chgflw_vld_s1;
    assign fe_ctrl_bp2_chgflw_pld              = bp2_chgflw_pld_s1;
    assign fe_ctrl_entry_buffer_rdy            = entry_rdy_s0;

    //============================================================
    // Pipeline
    //============================================================
    // l0btb cycle 1
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      l0btb_pld_s0 <= {(ADDR_WIDTH*2+BPU_OFFSET_WIDTH+1){1'b0}};
        else                                            l0btb_pld_s0 <= l0btb_pld;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      l0btb_vld_s0 <= 1'b0;
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush)   l0btb_vld_s0 <= 1'b0;
        else                                            l0btb_vld_s0 <= l0btb_vld;
    end

    // bp cycle2
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            l0btb_pld_s1        <= {(ADDR_WIDTH*2+BPU_OFFSET_WIDTH+1){1'b0}};
            tage_pld_s1         <= {($bits(tage_pkg)){1'b0}};
            btb_pld_s1          <= {($bits(btb_pkg)){1'b0}};
        end
        else begin
            l0btb_pld_s1        <= l0btb_pld_s0;
            tage_pld_s1         <= tage_pld;
            btb_pld_s1          <= btb_pld;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            l0btb_vld_s1        <= 1'b0;
            tage_vld_s1         <= 1'b0;
            btb_vld_s1          <= 1'b0;
        end
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush | bp2_chgflw_vld_s1) begin
            l0btb_vld_s1        <= 1'b0;
            tage_vld_s1         <= 1'b0;
            btb_vld_s1          <= 1'b0;
        end
        else begin
            l0btb_vld_s1        <= l0btb_vld_s0;
            tage_vld_s1         <= tage_vld;
            btb_vld_s1          <= btb_vld;
        end
    end

    //============================================================
    // Prediction
    //============================================================
    // tage prediction
    assign alt_pred_res   = (prvd_hit[1] && ~prvd_hit_onehot[1][0]) ? alt_entry_pld.pred_cnt[TAGE_TX_PRED_WIDTH-1] : tage_pld_s1.tb_pred[TAGE_BASE_PRED_WIDTH-1];
    assign prvd_pred_res  = (prvd_hit[0] && prvd_hit_onehot[0][0])  ? tage_pld_s1.tb_pred[TAGE_BASE_PRED_WIDTH-1]  : prvd_entry_pld.pred_cnt[TAGE_TX_PRED_WIDTH-1];
    assign is_new_entry   = (prvd_entry_pld.u_cnt==0 && ((prvd_entry_pld.pred_cnt==`NEW_PRED_T)|(prvd_entry_pld.pred_cnt==`NEW_PRED_NT)));
    assign pred_res       = (prvd_hit[1] && ~(tage_pld_s1.use_alt_cnt[TAGE_USE_ALT_WIDTH-1] && is_new_entry)) ? prvd_pred_res : alt_pred_res;

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM+1; i=i+1) begin: GEN_HIT
            if (i==0) assign entry_hit[i] = 1'b1;
            else      assign entry_hit[i] = (tage_pld_s1.tx_entry[i-1].tag == tage_pld_s1.tx_hash_tag[i-1]) && tage_pld_s1.tx_entry[i-1].valid;
        end
    endgenerate

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_ENTRY_PLD
            assign tx_entry_pld[i] = tage_pld_s1.tx_entry[i];
        end
    endgenerate

    cmn_real_mux_onehot #(
        .WIDTH    (TAGE_TABLE_NUM                          ),
        .PLD_WIDTH($bits(tage_tx_field_pkg)                )
    ) u_prvd_mux (
        .select_onehot(prvd_hit_onehot[0][TAGE_TABLE_NUM:1]),
        .v_pld        (tx_entry_pld                        ),
        .select_pld   (prvd_entry_pld                      )
    );

    cmn_real_mux_onehot #(
        .WIDTH    (TAGE_TABLE_NUM                          ),
        .PLD_WIDTH($bits(tage_tx_field_pkg)                )
    ) u_alt_mux (
        .select_onehot(prvd_hit_onehot[1][TAGE_TABLE_NUM:1]),
        .v_pld        (tx_entry_pld                        ),
        .select_pld   (alt_entry_pld                       )
    );

    cmn_list_lead_one_rev #(
        .ENTRY_NUM(TAGE_TABLE_NUM+1                        ),
        .REQ_NUM  (2                                       )
    ) u_ld_one_rev(
        .v_entry_vld   (entry_hit                          ),
        .v_free_idx_oh (prvd_hit_onehot                    ),
        .v_free_idx_bin(prvd_hit_index                     ),
        .v_free_vld    (prvd_hit                           )
    );

    // btb prediction
    generate
        for (genvar i = 0; i < BTB_WAY_NUM; i=i+1) begin: GEN_PRED
            assign way_vld[i]          = btb_pld_s1.entry_ack_rdata.entry_way[i].valid;
            assign way_hit[i]          = (btb_pld_s1.hash_tag == btb_pld_s1.entry_ack_rdata.entry_way[i].tag) && way_vld[i];
            assign v_entry_way_pred[i] = {btb_pld_s1.entry_ack_rdata.entry_way[i].tgt_pc, btb_pld_s1.entry_ack_rdata.entry_way[i].offset,
                                          btb_pld_s1.entry_ack_rdata.entry_way[i].is_cext, btb_pld_s1.entry_ack_rdata.entry_way[i].carry};
        end
    endgenerate

    cmn_real_mux_onehot #(
        .WIDTH    (BTB_WAY_NUM                          ),
        .PLD_WIDTH(ADDR_WIDTH+BTB_OFFSET_WIDTH          )
    ) u_pld_sel (
        .select_onehot(way_hit                          ),
        .v_pld        (v_entry_way_pred                 ),
        .select_pld   (entry_way_pred                   )
    );

    // bp2 predict result alignment
    assign non_align_tgt_pc  = (|way_hit && pred_res) ? entry_way_pred[ADDR_WIDTH+BTB_OFFSET_WIDTH-1:BTB_OFFSET_WIDTH] : ({tage_pld_s1.pred_pc[ADDR_WIDTH-1:ALIGN_WIDTH], {ALIGN_WIDTH{1'b0}}} + FETCH_DATA_WIDTH/8);
    assign non_align_offset  = (|way_hit && pred_res) ? entry_way_pred[BTB_OFFSET_WIDTH-1:2]                           : ({BPU_OFFSET_WIDTH{1'b1}} - (tage_pld_s1.pred_pc[ALIGN_WIDTH-1:0]>>2));
    assign non_align_cext    = (|way_hit && pred_res) ? entry_way_pred[1]                                              : 1'b0;
    assign non_align_carry   = (|way_hit && pred_res) ? entry_way_pred[0]                                              : 1'b0;
    assign need_align        = ((non_align_offset << 1) + (non_align_cext ? non_align_carry : 1'b0)) >= btb_pld_s1.align_offset[BPU_OFFSET_WIDTH+2:1];

    assign bp2_tgt_pc        = need_align ? btb_pld_s1.align_pc_boundary : non_align_tgt_pc;
    assign bp2_offset        = need_align ? btb_pld_s1.align_offset      : non_align_offset;
    assign bp2_is_cext       = need_align ? 1'b0                         : non_align_cext;
    assign bp2_carry         = need_align ? 1'b0                         : non_align_carry;

    // bp1 and bp2 result compare
    assign bp2_cmp_tgt_pc    = non_align_tgt_pc;
    assign bp2_cmp_offset    = non_align_offset;
    assign bp2_cmp_is_cext   = non_align_cext;
    assign bp2_cmp_carry     = non_align_carry;
    assign bp2_tgt_pc_hit    = (tage_vld_s1 && btb_vld_s1) ? (l0btb_pld_s1.tgt_pc == bp2_cmp_tgt_pc) : 1'b1;
    assign bp2_offset_hit    = (tage_vld_s1 && btb_vld_s1) ? (((l0btb_pld_s1.offset == bp2_cmp_offset)
            && (l0btb_pld_s1.is_cext == bp2_cmp_is_cext)
            && (l0btb_pld_s1.carry == bp2_cmp_carry)))
    : 1'b1;

    //============================================================
    // Changeflow
    //============================================================
    assign bp2_chgflw_vld_s1                          = tage_vld_s1 && btb_vld_s1 && (~bp2_tgt_pc_hit | ~bp2_offset_hit);
    assign bp2_chgflw_pld_s1.taken                    = pred_res && ~need_align;
    assign bp2_chgflw_pld_s1.pred_pc                  = tage_pld_s1.pred_pc;
    assign bp2_chgflw_pld_s1.offset                   = bp2_offset;
    assign bp2_chgflw_pld_s1.is_cext                  = bp2_is_cext;
    assign bp2_chgflw_pld_s1.carry                    = bp2_carry;
    assign bp2_chgflw_pld_s1.tgt_pc                   = bp2_tgt_pc;

    //============================================================
    // Entry Buffer
    //============================================================
    assign entry_vld_s0 = l0btb_vld;
    assign entry_vld_s1 = tage_vld_s1 && btb_vld_s1;

    assign entry_pld_s1.pred_pc                       = tage_pld_s1.pred_pc;
    assign entry_pld_s1.tage_entry.entry.tb_idx       = tage_pld_s1.tb_idx;
    assign entry_pld_s1.tage_entry.entry.tb_pred      = tage_pld_s1.tb_pred;
    assign entry_pld_s1.tage_entry.entry.pred_taken   = pred_res;
    assign entry_pld_s1.tage_entry.entry.pred_diff    = prvd_pred_res ^ alt_pred_res;
    assign entry_pld_s1.tage_entry.entry.prvd_idx     = prvd_hit_onehot[0];

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_TAGE_ENTRY_PLD
            assign entry_pld_s1.tage_entry.entry.tx_entry[i].valid    = tage_pld_s1.tx_entry[i].valid;
            assign entry_pld_s1.tage_entry.entry.tx_entry[i].pred_cnt = tage_pld_s1.tx_entry[i].pred_cnt;
            assign entry_pld_s1.tage_entry.entry.tx_entry[i].u_cnt    = tage_pld_s1.tx_entry[i].u_cnt;
            assign entry_pld_s1.tage_entry.entry.tx_entry[i].index    = tage_pld_s1.tx_hash_idx[i];
            assign entry_pld_s1.tage_entry.entry.tx_entry[i].tag      = tage_pld_s1.tx_hash_tag[i];
        end
    endgenerate

    assign entry_pld_s1.tage_entry.update.taken       = 1'b0;
    assign entry_pld_s1.tage_entry.update.mispred     = 1'b0;
    assign entry_pld_s1.tage_entry.update.alloc_id    = {(TAGE_TABLE_NUM){1'b0}};
    assign entry_pld_s1.tage_entry.update.tb_pred_add = 1'b0;
    assign entry_pld_s1.tage_entry.update.tb_pred_sub = 1'b0;

    assign entry_pld_s1.btb_entry.index               = btb_pld_s1.hash_idx;
    assign entry_pld_s1.btb_entry.tag                 = btb_pld_s1.hash_tag;
    assign entry_pld_s1.btb_entry.way_hit             = way_hit;
    assign entry_pld_s1.btb_entry.real_taken          = pred_res;
    assign entry_pld_s1.btb_entry.entry               = btb_pld_s1.entry_ack_rdata;

    assign entry_update_vld                           = fe_ctrl_be_chgflw_vld;
    assign entry_update_pld                           = fe_ctrl_be_chgflw_pld;
    assign entry_rdy_m                                = tage_w_vld && btb_w_vld;

    toy_bpu_bpdec_entry_buffer u_entry_buffer(
        .clk             (clk                                ),
        .rst_n           (rst_n                              ),
        .be_flush        (fe_ctrl_be_flush                   ),
        .ras_flush       (fe_ctrl_ras_flush                  ),
        .bp2_flush       (bp2_chgflw_vld_s1                  ),
        .s_vld_s0        (entry_vld_s0                       ),
        .s_rdy_s0        (entry_rdy_s0                       ),
        .s_pld_s0        (btb_bypass_pld                     ),
        .s_ptr_s0        (btb_bypass_ptr                     ),
        .s_ena_s0        (btb_bypass_ena                     ),
        .s_vld_s1        (entry_vld_s1                       ),
        .s_pld_s1        (entry_pld_s1                       ),
        .s_update_vld    (entry_update_vld                   ),
        .s_update_pld    (entry_update_pld                   ),
        .s_update_enqueue(fe_ctrl_ras_enqueue_vld            ),
        .m_vld           (entry_vld_m                        ),
        .m_rdy           (entry_rdy_m                        ),
        .m_pld           (entry_pld_m                        )
    );


endmodule 