module toy_bpu_btb
    import toy_pack::*;
    (
        input logic                                             clk,
        input logic                                             rst_n,

        // PCGEN =============================================================
        input logic                                             pcgen_vld,
        input logic [ADDR_WIDTH-1:0]                            pcgen_pc,

        // GHR ===============================================================
        // input   logic [GHR_LENGTH-1:0]                           ghr,

        // MEM MODEL =========================================================
        output logic                                            mem_req_vld,
        output logic         [BTB_WAY_NUM-1:0]                  mem_req_wren,
        output logic         [BTB_INDEX_WIDTH-1:0]              mem_req_addr,
        output btb_entry_pkg                                    mem_req_wdata,
        input  btb_entry_pkg                                    mem_ack_rdata,

        // BP DEC ============================================================
        output  logic                                           bpdec_btb_vld,
        output  btb_pkg                                         bpdec_btb_pld,

        input btb_entry_buffer_pkg                              bpdec_entry_buffer_pld [ENTRY_BUFFER_NUM-1:0],
        input logic                [ENTRY_BUFFER_PTR_WIDTH:0]   bpdec_entry_buffer_ptr,
        input logic                [ENTRY_BUFFER_NUM-1:0]       bpdec_entry_buffer_ena,

        output logic                                            bpdec_btb_update_vld,
        input  logic                                            bpdec_btb_update_rdy,
        input  btb_entry_buffer_pkg                             bpdec_btb_update_pld,

        // FE Controller =====================================================
        input   logic                                           fe_ctrl_bp2_chgflw_vld,
        input   logic                                           fe_ctrl_ras_flush,
        input   logic                                           fe_ctrl_ras_enqueue_vld,
        input   logic   [ADDR_WIDTH-1:0]                        fe_ctrl_ras_enqueue_pld,
        input   logic                                           fe_ctrl_be_flush,
        input   logic                                           fe_ctrl_be_chgflw_vld,
        input   logic   [ADDR_WIDTH-1:0]                        fe_ctrl_be_chgflw_pld
    );

    logic                [BTB_INDEX_WIDTH-1:0]             hist_pc;
    logic                [BTB_INDEX_WIDTH-1:0]             hist_pc_reg     [4:0];
    logic                [BTB_INDEX_WIDTH-1:0]             eq_hist_pc_reg  [3:0];
    logic                [BTB_INDEX_WIDTH-1:0]             rtu_hist_pc_reg [3:0];

    logic                [BTB_INDEX_WIDTH-1:0]             hash_idx;
    logic                [BTB_TAG_WIDTH-1:0]               hash_tag;
    logic                                                  entry_req_vld;
    logic                                                  entry_req_wren;
    logic                [BTB_WAY_NUM-1:0]                 v_entry_req_wren;
    logic                [BTB_INDEX_WIDTH-1:0]             entry_req_addr;
    btb_entry_pkg                                          entry_req_wdata;
    btb_entry_pkg                                          entry_ack_rdata;

    logic                [ADDR_WIDTH-1:0]                  pcgen_pc_s1;
    logic                                                  pcgen_vld_s1;
    logic                [BTB_INDEX_WIDTH-1:0]             hash_idx_s1;
    logic                [BTB_TAG_WIDTH-1:0]               hash_tag_s1;


    logic                [ADDR_WIDTH-1 :0]                 align_pc_boundary;
    logic                [ADDR_WIDTH-1 :0]                 align_offset;

    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_tag_hit;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_idx_hit;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_hit_high;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_hit_low;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_hit_oh;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_hit_high_oh;
    logic                [ENTRY_BUFFER_NUM-1:0]            bypass_hit_low_oh;
    logic                                                  bypass_vld_high;
    logic                                                  bypass_vld_low;
    btb_entry_buffer_pkg                                   bypass_pld_s0;
    logic                                                  bypass_vld_s0;
    btb_entry_buffer_pkg                                   bypass_pld_s1;
    logic                                                  bypass_vld_s1;



    //===============================================
    //  pred result to other module
    //===============================================
    assign bpdec_btb_vld                    = pcgen_vld_s1 | bypass_vld_s1;
    assign bpdec_btb_pld.pred_pc            = pcgen_pc_s1;
    assign bpdec_btb_pld.hash_idx           = hash_idx_s1;
    assign bpdec_btb_pld.hash_tag           = hash_tag_s1;
    assign bpdec_btb_pld.entry_ack_rdata    = bypass_vld_s1 ? bypass_pld_s1.entry : entry_ack_rdata;
    assign bpdec_btb_pld.align_offset       = align_offset;
    assign bpdec_btb_pld.align_pc_boundary  = align_pc_boundary;

    assign bpdec_btb_update_vld             = entry_req_wren;


    //===============================================
    //  hist_pc_reg
    //===============================================
    assign hist_pc = {hist_pc_reg[3][9:8], hist_pc_reg[2][7:6], hist_pc_reg[1][5:4], hist_pc_reg[0][3:2], pcgen_pc[2:1]};

    generate
        for(genvar i=0; i < 5; i = i + 1) begin: GEN_HIST_REG
            if(i==0) begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          hist_pc_reg[0] <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld && fe_ctrl_be_flush)  hist_pc_reg[0] <= fe_ctrl_be_chgflw_pld[BTB_INDEX_WIDTH-1:0];
                    else if(fe_ctrl_ras_flush)                          hist_pc_reg[0] <= fe_ctrl_ras_enqueue_pld[BTB_INDEX_WIDTH-1:0];
                    else if(fe_ctrl_bp2_chgflw_vld)                     hist_pc_reg[0] <= hist_pc_reg[1];
                    else if(pcgen_vld)                                  hist_pc_reg[0] <= pcgen_pc[BTB_INDEX_WIDTH-1:0];
                end
            end
            else if(i==4) begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          hist_pc_reg[4]    <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld && fe_ctrl_be_flush)  hist_pc_reg[4]    <= rtu_hist_pc_reg[3];
                    else if(fe_ctrl_ras_flush)                          hist_pc_reg[4]    <= eq_hist_pc_reg[3];
                    else if(fe_ctrl_bp2_chgflw_vld)                     hist_pc_reg[4]    <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(pcgen_vld)                                  hist_pc_reg[4]    <= hist_pc_reg[3];
                end
            end
            else begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          hist_pc_reg[i]    <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld && fe_ctrl_be_flush)  hist_pc_reg[i]    <= rtu_hist_pc_reg[i-1];
                    else if(fe_ctrl_ras_flush)                          hist_pc_reg[i]    <= eq_hist_pc_reg[i-1];
                    else if(fe_ctrl_bp2_chgflw_vld)                     hist_pc_reg[i]    <= hist_pc_reg[i+1];
                    else if(pcgen_vld)                                  hist_pc_reg[i]    <= hist_pc_reg[i-1];
                end
            end
        end
    endgenerate

    // for ras flush
    generate
        for(genvar i=0; i < 3; i = i + 1) begin: GEN_RAS_HIST_REG
            if(i==0) begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          eq_hist_pc_reg[0] <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld&&fe_ctrl_be_flush)    eq_hist_pc_reg[0] <= fe_ctrl_be_chgflw_pld[BTB_INDEX_WIDTH-1:0];
                    else if(fe_ctrl_ras_enqueue_vld)                    eq_hist_pc_reg[0] <= fe_ctrl_ras_enqueue_pld[BTB_INDEX_WIDTH-1:0];
                end
            end
            else begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          eq_hist_pc_reg[i] <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld&&fe_ctrl_be_flush)    eq_hist_pc_reg[i] <= rtu_hist_pc_reg[i-1];
                    else if(fe_ctrl_ras_enqueue_vld)                    eq_hist_pc_reg[i] <= eq_hist_pc_reg[i-1];
                end
            end
        end
    endgenerate

    // for be flush and commit
    generate
        for(genvar i=0; i < 3; i = i + 1) begin: GEN_BE_HIST_REG
            if(i==0) begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          rtu_hist_pc_reg[0] <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld)                      rtu_hist_pc_reg[0] <= fe_ctrl_be_chgflw_pld[BTB_INDEX_WIDTH-1:0];
                end
            end
            else begin
                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)                                          rtu_hist_pc_reg[i] <= {BTB_INDEX_WIDTH{1'b0}};
                    else if(fe_ctrl_be_chgflw_vld)                      rtu_hist_pc_reg[i] <= rtu_hist_pc_reg[i-1];
                end
            end
        end
    endgenerate


    //===============================================
    //  Preprocess
    //===============================================
    assign hash_idx                 = {pcgen_pc[2*BTB_INDEX_WIDTH+1:BTB_INDEX_WIDTH+1]} ^ pcgen_pc[BTB_INDEX_WIDTH:1] ^ hist_pc;
    assign hash_tag                 = {pcgen_pc[2*BTB_TAG_WIDTH+1:BTB_TAG_WIDTH+1]} ^ pcgen_pc[BTB_TAG_WIDTH:1];

    assign entry_req_vld            = pcgen_vld | bpdec_btb_update_rdy;
    assign entry_req_wren           = ~pcgen_vld;
    assign v_entry_req_wren         = {BTB_WAY_NUM{entry_req_wren && bpdec_btb_update_pld.real_taken}} & bpdec_btb_update_pld.way_hit;
    assign entry_req_addr           = entry_req_wren ? bpdec_btb_update_pld.index : hash_idx;
    assign entry_req_wdata          = bpdec_btb_update_pld.entry;


    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                     hash_idx_s1 <= {BTB_INDEX_WIDTH{1'b0}};
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush)   hash_idx_s1 <= {BTB_INDEX_WIDTH{1'b0}};
        else                                            hash_idx_s1 <= hash_idx;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                     hash_tag_s1 <= {BTB_TAG_WIDTH{1'b0}};
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush)   hash_tag_s1 <= {BTB_TAG_WIDTH{1'b0}};
        else                                            hash_tag_s1 <= hash_tag;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                     pcgen_pc_s1 <= {ADDR_WIDTH{1'b0}};
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush)   pcgen_pc_s1 <= {ADDR_WIDTH{1'b0}};
        else                                            pcgen_pc_s1 <= pcgen_pc;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                     pcgen_vld_s1 <= 1'b0;
        else if(fe_ctrl_be_flush | fe_ctrl_ras_flush)   pcgen_vld_s1 <= 1'b0;
        else if(fe_ctrl_bp2_chgflw_vld)                 pcgen_vld_s1 <= 1'b0;
        else                                            pcgen_vld_s1 <= pcgen_vld;
    end

    //===============================================
    //  Bypass
    //===============================================
    generate
        for(genvar i = 0; i < ENTRY_BUFFER_NUM; i = i + 1) begin: GEN_BYPASS_HIT
            assign bypass_idx_hit[i]  = bpdec_entry_buffer_pld[i].index == hash_idx;
            assign bypass_tag_hit[i]  = bpdec_entry_buffer_pld[i].tag   == hash_tag;
            assign bypass_hit_high[i] = (i < bpdec_entry_buffer_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]) && bpdec_entry_buffer_ena[i] ? (bypass_idx_hit[i] && bypass_tag_hit[i])   : 1'b0;
            assign bypass_hit_low[i]  = (i >= bpdec_entry_buffer_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]) && bpdec_entry_buffer_ena[i]  ? (bypass_idx_hit[i] && bypass_tag_hit[i]) : 1'b0;
        end
    endgenerate

    assign bypass_hit_oh    = bypass_vld_high ? bypass_hit_high_oh : bypass_hit_low_oh;
    assign bypass_vld_s0    = bypass_vld_high | bypass_vld_low;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            bypass_vld_s1 <= 1'b0;
        end
        else if(pcgen_vld) begin
            bypass_vld_s1 <= bypass_vld_s0;
        end
        else begin
            bypass_vld_s1 <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            bypass_pld_s1 <= {($bits(btb_entry_buffer_pkg)){1'b0}};
        end
        else if(bypass_vld_s0) begin
            bypass_pld_s1 <= bypass_pld_s0;
        end
    end

    cmn_real_mux_onehot #(
        .WIDTH    (ENTRY_BUFFER_NUM           ),
        .PLD_WIDTH($bits(btb_entry_buffer_pkg))
    ) u_bypass_mux (
        .select_onehot(bypass_hit_oh         ),
        .v_pld        (bpdec_entry_buffer_pld),
        .select_pld   (bypass_pld_s0         )
    );

    cmn_lead_one_rev #(
        .ENTRY_NUM(ENTRY_BUFFER_NUM)
    ) u_lead_one_high (
        .v_entry_vld   (bypass_hit_high   ),
        .v_free_idx_oh (bypass_hit_high_oh),
        .v_free_vld    (bypass_vld_high   ),
        .v_free_idx_bin(                  )
    );

    cmn_lead_one_rev #(
        .ENTRY_NUM(ENTRY_BUFFER_NUM)
    ) u_lead_one_low (
        .v_entry_vld   (bypass_hit_low   ),
        .v_free_idx_oh (bypass_hit_low_oh),
        .v_free_vld    (bypass_vld_low   ),
        .v_free_idx_bin(                 )
    );

    //===============================================
    //  Align
    //===============================================
    assign align_pc_boundary       = {pcgen_pc_s1[ADDR_WIDTH-1:ALIGN_WIDTH], {ALIGN_WIDTH{1'b0}}} + FETCH_DATA_WIDTH/8;
    assign align_offset            = (align_pc_boundary - pcgen_pc_s1);


    //===============================================
    //  4 way btb entry
    //===============================================
    toy_bpu_btb_entry u_btb_entry(
        .clk          (clk                      ),
        .rst_n        (rst_n                    ),
        .req_vld      (entry_req_vld            ),
        .req_wren     (v_entry_req_wren         ),
        .req_addr     (entry_req_addr           ),
        .req_wdata    (entry_req_wdata          ),
        .ack_rdata    (entry_ack_rdata          ),
        .mem_req_vld  (mem_req_vld              ),
        .mem_req_wren (mem_req_wren             ),
        .mem_req_addr (mem_req_addr             ),
        .mem_req_wdata(mem_req_wdata            ),
        .mem_ack_rdata(mem_ack_rdata            )
    );


endmodule 