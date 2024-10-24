
module toy_bpu_l0btb
    import toy_pack::*;
    (
        input   logic                    clk,
        input   logic                    rst_n,

        // PC GEN ============================================================
        input   logic                    pcgen_vld           ,
        input   logic [ADDR_WIDTH-1:0]   pcgen_pc            ,

        // GHR ===============================================================
        //  input   logic [GHR_LENGTH-1:0]  ghr                 ,

        // BP DEC ============================================================
        output  logic                    bpdec_l0btb_vld    ,
        output  bpu_pkg                  bpdec_l0btb_pld    ,

        // FE Controller =====================================================
        input   logic                    fe_ctrl_chgflw_vld_i ,
        input   bpu_pkg                  fe_ctrl_chgflw_pld_i ,
        output  bpu_pkg                  fe_ctrl_chgflw_pld_o   ,
        output  logic                    fe_ctrl_chgflw_vld_o

    );

    logic           [BP0_ENTRY_NUM-1:0]       v_entry_vld;
    l0btb_entry_pkg                           v_entry_pld         [BP0_ENTRY_NUM-1:0];
    logic           [BP0_TAG_WIDTH-1:0]       entry_check_tag;
    logic                                     entry_check_vld;
    logic           [BP0_ENTRY_NUM-1:0]       entry_check_hit;

    logic                                     entry_buffer_bypass_hit;
    logic           [BP0_ENTRY_NUM-1:0]       entry_pred_hit;
    logic           [ADDR_WIDTH-1:0]          v_entry_pred_tgt_pc     [BP0_ENTRY_NUM:0];
    logic           [BPU_OFFSET_WIDTH-1:0]    v_entry_pred_offset     [BP0_ENTRY_NUM:0];
    logic           [BP0_ENTRY_NUM:0]         v_entry_pred_cext;
    logic           [BP0_ENTRY_NUM:0]         v_entry_pred_carry;
    logic           [BP0_ENTRY_NUM:0]         v_entry_rev_tgt_pc      [ADDR_WIDTH-1:0];
    logic           [BP0_ENTRY_NUM:0]         v_entry_rev_offset      [BPU_OFFSET_WIDTH-1:0];
    bpu_pkg                                   entry_pred_pld;
    logic           [ADDR_WIDTH-1:0]          entry_pred_tgt_pc;
    logic           [BPU_OFFSET_WIDTH-1:0]    entry_pred_offset;
    logic                                     entry_pred_cext;
    logic                                     entry_pred_carry;
    logic                                     entry_pred_taken;

    l0btb_entry_pkg                           entry_update_pld;
    bpu_pkg                                   entry_buffer_update_pld;
    logic                                     entry_buffer_update_vld;
    logic           [BP0_ENTRY_NUM-1:0]       v_entry_update;
    logic           [BP0_ENTRY_NUM-1:0]       v_entry_update_inv;
    logic           [BP0_ENTRY_NUM-1:0]       v_entry_update_tag_hit;
    logic                                     entry_update_ntaken;
    logic           [BP0_ENTRY_NUM-1:0]       entry_update_oh;


    //==============================================
    // Interface
    //==============================================
    assign bpdec_l0btb_pld                  = entry_pred_pld;
    assign bpdec_l0btb_vld                  = pcgen_vld;

    assign fe_ctrl_chgflw_pld_o             = entry_pred_pld;
    assign fe_ctrl_chgflw_vld_o             = pcgen_vld;

    //==============================================
    // Check
    //==============================================
    assign entry_check_tag                  = pcgen_pc[BP0_TAG_WIDTH:1];
    assign entry_check_vld                  = pcgen_vld;

    assign entry_buffer_bypass_hit          = entry_buffer_update_vld && (entry_buffer_update_pld.pred_pc[BP0_TAG_WIDTH:1]==entry_check_tag);
    assign entry_pred_hit                   = {BP0_ENTRY_NUM{~entry_buffer_bypass_hit}} & entry_check_hit;
    assign entry_pred_taken                 = entry_buffer_bypass_hit || (|entry_check_hit);  

    assign entry_pred_pld.taken             = entry_pred_taken;
    assign entry_pred_pld.pred_pc           = pcgen_pc;
    assign entry_pred_pld.tgt_pc            = entry_pred_taken ? entry_pred_tgt_pc : ({pcgen_pc[ADDR_WIDTH-1:ALIGN_WIDTH], {ALIGN_WIDTH{1'b0}}} + FETCH_DATA_WIDTH/8);
    assign entry_pred_pld.offset            = entry_pred_taken ? entry_pred_offset : ({(BPU_OFFSET_WIDTH){1'b1}} - (pcgen_pc[ALIGN_WIDTH-1:0]>>2));
    assign entry_pred_pld.is_cext           = entry_pred_taken ? entry_pred_cext   : 1'b0;
    assign entry_pred_pld.carry             = entry_pred_taken ? entry_pred_carry  : 1'b0;
    assign entry_pred_pld.need_align        = 0;

    // generate pred result (real_onehot_mux)
    generate
        for(genvar i = 0; i < BP0_ENTRY_NUM + 1; i=i+1) begin: ENTRY_PRED_GEN
            if(i==BP0_ENTRY_NUM) begin
                assign v_entry_pred_tgt_pc[i]   = {ADDR_WIDTH{entry_buffer_bypass_hit}}       & entry_buffer_update_pld.tgt_pc;
                assign v_entry_pred_offset[i]   = {BPU_OFFSET_WIDTH{entry_buffer_bypass_hit}} & entry_buffer_update_pld.offset;
                assign v_entry_pred_cext[i]     = entry_buffer_bypass_hit                     & entry_buffer_update_pld.is_cext;
                assign v_entry_pred_carry[i]    = entry_buffer_bypass_hit                     & entry_buffer_update_pld.carry;
            end
            else begin
                assign v_entry_pred_tgt_pc[i]   = {ADDR_WIDTH{entry_pred_hit[i]}}             & v_entry_pld[i].tgt_pc;
                assign v_entry_pred_offset[i]   = {BPU_OFFSET_WIDTH{entry_pred_hit[i]}}       & v_entry_pld[i].offset;
                assign v_entry_pred_cext[i]     = entry_pred_hit[i]                           & v_entry_pld[i].is_cext;
                assign v_entry_pred_carry[i]    = entry_pred_hit[i]                           & v_entry_pld[i].carry;
            end
        end
    endgenerate

    generate
        for(genvar i = 0; i < BP0_ENTRY_NUM + 1; i=i+1) begin: ENTRY_PRED_REV_COL
            for(genvar j = 0; j < ADDR_WIDTH; j=j+1) begin: ENTRY_TGT_PC_ROW
                assign v_entry_rev_tgt_pc[j][i] = v_entry_pred_tgt_pc[i][j];
            end
            for(genvar j = 0; j < BPU_OFFSET_WIDTH; j=j+1) begin: ENTRY_OFFSET_ROW
                assign v_entry_rev_offset[j][i] = v_entry_pred_offset[i][j];
            end
        end
    endgenerate

    generate
        for(genvar i = 0; i < ADDR_WIDTH; i=i+1) begin : ENTRY_TGT_PC_GEN
            assign entry_pred_tgt_pc[i] = |v_entry_rev_tgt_pc[i];
        end
        for(genvar i = 0; i < BPU_OFFSET_WIDTH; i=i+1) begin : ENTRY_OFFSET_GEN
            assign entry_pred_offset[i] = |v_entry_rev_offset[i];
        end

    endgenerate

    assign entry_pred_cext                  = |v_entry_pred_cext;
    assign entry_pred_carry                 = |v_entry_pred_carry;


    //==============================================
    // update
    //==============================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         entry_buffer_update_vld <= 1'b0;
        else if (fe_ctrl_chgflw_vld_i)      entry_buffer_update_vld <= 1'b1;
        else                                entry_buffer_update_vld <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         entry_buffer_update_pld <= {($bits(bpu_pkg)){1'b0}};
        else if (fe_ctrl_chgflw_vld_i)      entry_buffer_update_pld <= fe_ctrl_chgflw_pld_i;
    end

    assign entry_update_pld.tag        = entry_buffer_update_pld.pred_pc[BP0_TAG_WIDTH:1];
    assign entry_update_pld.offset     = entry_buffer_update_pld.offset;
    assign entry_update_pld.is_cext    = entry_buffer_update_pld.is_cext;
    assign entry_update_pld.carry      = entry_buffer_update_pld.carry;
    assign entry_update_pld.tgt_pc     = entry_buffer_update_pld.tgt_pc;
    assign entry_update_ntaken         = ~entry_buffer_update_pld.taken;

    // update pointer when change flow
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          entry_update_oh   <= {{(BP0_ENTRY_NUM-1){1'b0}}, 1'b1};
        else if(fe_ctrl_chgflw_vld_i)       entry_update_oh   <= {entry_update_oh[BP0_ENTRY_NUM-2:0], entry_update_oh[BP0_ENTRY_NUM-1]};
    end

    generate
        for(genvar i = 0; i < BP0_ENTRY_NUM; i=i+1) begin: L0BTB_ENTRY_GEN
            // check
            assign entry_check_hit[i]        = entry_check_vld && v_entry_vld[i] && (v_entry_pld[i].tag==entry_check_tag);

            // update:  when tag hit, then invalidate or update entry
            assign v_entry_update_tag_hit[i] = v_entry_vld[i] && (v_entry_pld[i].tag==entry_update_pld.tag);
            assign v_entry_update[i]         = entry_buffer_update_vld && (|v_entry_update_tag_hit ? v_entry_update_tag_hit[i] : entry_update_oh[i]);
            assign v_entry_update_inv[i]     = v_entry_update_tag_hit[i] && entry_update_ntaken;

            toy_bpu_l0btb_entry u_entry(
                .clk             (clk                  ),
                .rst_n           (rst_n                ),
                .entry_update    (v_entry_update[i]    ),
                .entry_update_inv(v_entry_update_inv[i]),
                .entry_update_pld(entry_update_pld     ),
                .entry_vld       (v_entry_vld[i]       ),
                .entry_pld       (v_entry_pld[i]       )
            );
        end
    endgenerate

endmodule 