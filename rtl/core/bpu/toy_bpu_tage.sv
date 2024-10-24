module toy_bpu_tage
    import toy_pack::*;
    (
        input  logic                                       clk,
        input  logic                                       rst_n,

        // PC GEN =============================================
        input  logic                                       pcgen_vld,
        input  logic   [ADDR_WIDTH-1:0]                    pcgen_pc,

        // GHR ================================================
        input  logic    [GHR_LENGTH-1:0]                   ghr,

        // Mem Model ==========================================
        output logic                                       tb_mem_req_wren,
        output logic                                       tb_mem_req_vld,
        output logic [TAGE_BASE_INDEX_WIDTH-1:0]           tb_mem_req_addr,
        output logic [TAGE_BASE_PRED_WIDTH-1:0]            tb_mem_req_wdata,
        input  logic [TAGE_BASE_PRED_WIDTH-1:0]            tb_mem_ack_rdata,

        output logic             [TAGE_TABLE_NUM-1:0]      tx_mem_req_vld,
        output logic             [TAGE_TABLE_NUM-1:0]      tx_mem_req_wren,
        output logic             [TAGE_TX_INDEX_WIDTH-1:0] tx_mem_req_addr  [TAGE_TABLE_NUM-1:0],
        output tage_tx_field_pkg                           tx_mem_req_wdata [TAGE_TABLE_NUM-1:0],
        input  tage_tx_field_pkg                           tx_mem_ack_rdata [TAGE_TABLE_NUM-1:0],

        // BP DEC =============================================
        output logic                                       bpdec_tage_vld,
        output tage_pkg                                    bpdec_tage_pld,

        output logic                                       bpdec_tage_update_vld,
        input  logic                                       bpdec_tage_update_rdy,
        input  tage_entry_buffer_pkg                       bpdec_tage_update_pld,

        // FE Controller ======================================
        input  logic                                       fe_ctrl_flush
    );

    logic             [TAGE_CLR_WIDTH-1:0]             clear_cnt;
    logic                                              u_clear;

    logic             [TAGE_BASE_INDEX_WIDTH-1:0]      tb_idx;
    logic             [TAGE_TX_INDEX_WIDTH-1:0]        tx_hash_idx     [TAGE_TABLE_NUM-1:0];
    logic             [TAGE_TX_TAG_WIDTH-1:0]          tx_hash_tag     [TAGE_TABLE_NUM-1:0];
    logic             [TAGE_TX_TAG_WIDTH-1:0]          tx_hash_tag_s1  [TAGE_TABLE_NUM-1:0];
    logic             [TAGE_BASE_INDEX_WIDTH-1:0]      tb_idx_s1;
    logic             [TAGE_TX_INDEX_WIDTH-1:0]        tx_hash_idx_s1  [TAGE_TABLE_NUM-1:0];
    logic             [ADDR_WIDTH-1:0]                 pred_pc_s1;
    logic                                              pcgen_vld_s1;    

    logic                                              tx_req_vld;
    logic                                              tx_req_wren;
    logic             [TAGE_TABLE_NUM-1:0]             tx_v_req_wren;
    logic             [TAGE_BASE_INDEX_WIDTH-1:0]      tb_req_addr;
    logic                                              tb_req_wren;
    logic             [TAGE_BASE_PRED_WIDTH-1:0]       tb_req_wdata;
    logic             [TAGE_BASE_PRED_WIDTH-1:0]       tb_ack_rdata;
    logic             [TAGE_TX_INDEX_WIDTH-1:0]        tx_req_addr     [TAGE_TABLE_NUM-1:0];
    tage_tx_field_pkg                                  tx_req_wdata    [TAGE_TABLE_NUM-1:0];
    tage_tx_field_pkg                                  tx_ack_rdata    [TAGE_TABLE_NUM-1:0];

    logic             [TAGE_USE_ALT_WIDTH-1:0]         use_alt_cnt;
    logic                                              use_alt_cnt_add;
    logic                                              use_alt_cnt_sub;

    logic             [GHR_LENGTH:0]                   real_ghr;

    //===============================================
    //  pred result to other module
    //===============================================
    assign bpdec_tage_vld              = pcgen_vld_s1;
    assign bpdec_tage_pld.pred_pc      = pred_pc_s1;
    assign bpdec_tage_pld.tb_idx       = tb_idx_s1;
    assign bpdec_tage_pld.tb_pred      = tb_ack_rdata;

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_BPDEC_PLD
            assign bpdec_tage_pld.tx_hash_idx[i]  = tx_hash_idx_s1[i];
            assign bpdec_tage_pld.tx_hash_tag[i]  = tx_hash_tag_s1[i];
            assign bpdec_tage_pld.tx_entry[i]     = tx_ack_rdata[i];
        end
    endgenerate

    assign bpdec_tage_pld.use_alt_cnt  = use_alt_cnt;
    assign bpdec_tage_update_vld       = tx_req_wren;

    //===============================================
    //  clear counter
    //===============================================
    assign u_clear = (clear_cnt == TAGE_CLR_CYCLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          clear_cnt  <= {TAGE_CLR_WIDTH{1'b0}};
        else                clear_cnt  <= clear_cnt + 1'b1;
    end

    //===============================================
    //  Preprocess
    //===============================================
    // hash index and tag (opt -> compress ghr)
    assign real_ghr       = ghr[GHR_LENGTH-1:0];

    assign tb_idx         = pcgen_pc[TAGE_BASE_INDEX_WIDTH:1];

    assign tx_hash_idx[0] = pcgen_pc[TAGE_T0_INDEX_WIDTH:1]
                          ^ real_ghr[TAGE_T0_INDEX_WIDTH-1:0];
    assign tx_hash_idx[1] = pcgen_pc[TAGE_T1_INDEX_WIDTH:1]
                          ^ real_ghr[TAGE_T1_INDEX_WIDTH-1:0]
                          ^ real_ghr[TAGE_T1_INDEX_WIDTH*2-1:TAGE_T1_INDEX_WIDTH];
    assign tx_hash_idx[2] = pcgen_pc[TAGE_T2_INDEX_WIDTH:1]
                          ^ real_ghr[TAGE_T2_INDEX_WIDTH-1:0]
                          ^ real_ghr[TAGE_T2_INDEX_WIDTH*2-1:TAGE_T2_INDEX_WIDTH]
                          ^ real_ghr[TAGE_T2_INDEX_WIDTH*3-1:TAGE_T2_INDEX_WIDTH*2];
    assign tx_hash_idx[3] = pcgen_pc[TAGE_T3_INDEX_WIDTH:1]
                          ^ real_ghr[TAGE_T3_INDEX_WIDTH-1:0]
                          ^ real_ghr[TAGE_T3_INDEX_WIDTH*2-1:TAGE_T3_INDEX_WIDTH]
                          ^ real_ghr[TAGE_T3_INDEX_WIDTH*3-1:TAGE_T3_INDEX_WIDTH*2]
                          ^ real_ghr[TAGE_T3_INDEX_WIDTH*4-1:TAGE_T3_INDEX_WIDTH*3];

    assign tx_hash_tag[0] = pcgen_pc[TAGE_T0_TAG_WIDTH:1]
                          ^ real_ghr[TAGE_T0_TAG_WIDTH-1:0]
                          ^ real_ghr[TAGE_T0_HIST_LEN-1:TAGE_T0_TAG_WIDTH];
    assign tx_hash_tag[1] = pcgen_pc[TAGE_T1_TAG_WIDTH:1]
                          ^ real_ghr[TAGE_T1_TAG_WIDTH-1:0]
                          ^ real_ghr[TAGE_T1_TAG_WIDTH*2-1:TAGE_T1_TAG_WIDTH]
                          ^ real_ghr[TAGE_T1_HIST_LEN-1:TAGE_T1_TAG_WIDTH*2];
    assign tx_hash_tag[2] = pcgen_pc[TAGE_T2_TAG_WIDTH:1]
                          ^ real_ghr[TAGE_T2_TAG_WIDTH-1:0]
                          ^ real_ghr[TAGE_T2_TAG_WIDTH*2-1:TAGE_T2_TAG_WIDTH]
                          ^ real_ghr[TAGE_T2_TAG_WIDTH*3-1:TAGE_T2_TAG_WIDTH*2]
                          ^ real_ghr[TAGE_T2_HIST_LEN-1:TAGE_T2_TAG_WIDTH*3];
    assign tx_hash_tag[3] = pcgen_pc[TAGE_T3_TAG_WIDTH:1]
                          ^ real_ghr[TAGE_T3_TAG_WIDTH-1:0]
                          ^ real_ghr[TAGE_T3_TAG_WIDTH*2-1:TAGE_T3_TAG_WIDTH]
                          ^ real_ghr[TAGE_T3_TAG_WIDTH*3-1:TAGE_T3_TAG_WIDTH*2]
                          ^ real_ghr[TAGE_T3_TAG_WIDTH*4-1:TAGE_T3_TAG_WIDTH*3]
                          ^ real_ghr[TAGE_T3_HIST_LEN-1:TAGE_T3_TAG_WIDTH*4];

    // generate read and write signal
    assign tx_req_vld    = pcgen_vld                             // read for predict
                         | bpdec_tage_update_rdy;                // write for update
    assign tx_req_wren   = ~pcgen_vld;                           // write and no read req

    // process allocate info (can put into entry buffer)
    assign tb_req_wdata               = bpdec_tage_update_pld.entry.tb_pred;
    assign tb_req_addr                = tx_req_wren ? bpdec_tage_update_pld.entry.tb_idx : tb_idx;
    assign tb_req_wren                = tx_req_wren && bpdec_tage_update_pld.entry.prvd_idx[0];
    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_NEW_ENTRY
            assign tx_req_wdata[i].valid    = bpdec_tage_update_pld.update.alloc_id[i] ? 1'b1 
                                                                                       : bpdec_tage_update_pld.entry.tx_entry[i].valid;
            assign tx_req_wdata[i].pred_cnt = bpdec_tage_update_pld.update.alloc_id[i] ? (bpdec_tage_update_pld.update.taken ? `NEW_PRED_T : `NEW_PRED_NT)
                                                                                       : bpdec_tage_update_pld.entry.tx_entry[i].pred_cnt;
            assign tx_req_wdata[i].u_cnt    = bpdec_tage_update_pld.update.alloc_id[i] ? `NEW_U 
                                                                                       : bpdec_tage_update_pld.entry.tx_entry[i].u_cnt;
            assign tx_req_addr[i]           = tx_req_wren                              ? bpdec_tage_update_pld.entry.tx_entry[i].index 
                                                                                       : tx_hash_idx[i];
            assign tx_req_wdata[i].tag      = bpdec_tage_update_pld.entry.tx_entry[i].tag;
            assign tx_v_req_wren[i]         = tx_req_wren & tx_req_wdata[i].valid & (bpdec_tage_update_pld.update.alloc_id[i]|bpdec_tage_update_pld.entry.prvd_idx[i+1]);
        end
    endgenerate

    //===============================================
    //  UseAltCtr
    //===============================================
    assign use_alt_cnt_add  = bpdec_tage_update_pld.update.mispred;
    assign use_alt_cnt_sub  = ~bpdec_tage_update_pld.update.mispred;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                                   use_alt_cnt <= {TAGE_USE_ALT_WIDTH{1'b0}};
        else if(fe_ctrl_flush)                                       use_alt_cnt <= {TAGE_USE_ALT_WIDTH{1'b0}};
        else if(bpdec_tage_update_rdy&&bpdec_tage_update_rdy) begin
            if(use_alt_cnt_add && (use_alt_cnt < TAGE_USE_ALT_MAX))   use_alt_cnt <= use_alt_cnt + 1'b1;
            else if(use_alt_cnt_sub && (use_alt_cnt > 0))             use_alt_cnt <= use_alt_cnt - 1'b1;
        end
    end

    //===============================================
    //  Prediction
    //===============================================
    // buf hash tag and index, signal from pcgen
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         pcgen_vld_s1 <= 1'b0;
        else if(fe_ctrl_flush)              pcgen_vld_s1 <= 1'b0;
        else                                pcgen_vld_s1 <= pcgen_vld;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          pred_pc_s1 <= 1'b0;
        else if(fe_ctrl_flush)              pred_pc_s1 <= 1'b0;
        else if(pcgen_vld)                  pred_pc_s1 <= pcgen_pc;
    end

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: HASH_TAG_S1
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)                  tx_hash_tag_s1[i] <= {TAGE_TX_TAG_WIDTH{1'b0}};
                else if(fe_ctrl_flush)      tx_hash_tag_s1[i] <= {TAGE_TX_TAG_WIDTH{1'b0}};
                else if(pcgen_vld)          tx_hash_tag_s1[i] <= tx_hash_tag[i];
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          tb_idx_s1 <= {TAGE_BASE_INDEX_WIDTH{1'b0}};
        else if(fe_ctrl_flush)              tb_idx_s1 <= {TAGE_BASE_INDEX_WIDTH{1'b0}};
        else if(pcgen_vld)                  tb_idx_s1 <= tb_idx;
    end

    generate
        for(genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: HASH_IDX_S1
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)                  tx_hash_idx_s1[i] <= {TAGE_TX_INDEX_WIDTH{1'b0}};
                else if(fe_ctrl_flush)      tx_hash_idx_s1[i] <= {TAGE_TX_INDEX_WIDTH{1'b0}};
                else if(pcgen_vld)          tx_hash_idx_s1[i] <= tx_hash_idx[i];
            end
        end
    endgenerate


    //===============================================
    //  tage table
    //===============================================
    // bimodel base table 
    toy_bpu_tage_base_table u_tage_base(
        .clk          (clk                          ),
        .rst_n        (rst_n                        ),
        .req_vld      (tx_req_vld                   ),
        .req_wren     (tb_req_wren                  ),
        .req_addr     (tb_req_addr                  ),
        .req_wdata    (tb_req_wdata                 ),
        .ack_rdata    (tb_ack_rdata                 ),
        .mem_req_vld  (tb_mem_req_vld               ),
        .mem_req_wren (tb_mem_req_wren              ),
        .mem_req_addr (tb_mem_req_addr              ),
        .mem_req_wdata(tb_mem_req_wdata             ),
        .mem_ack_rdata(tb_mem_ack_rdata             )
    );
    // tage table
    generate 
        for (genvar i = 0; i < TAGE_TABLE_NUM; i = i + 1) begin: GEN_TAGE_TABLE
            toy_bpu_tage_tx_table u_tage_tx(
                .clk          (clk                          ),
                .rst_n        (rst_n                        ),
                .extra_rst    (u_clear                      ),
                .req_vld      (tx_req_vld                   ),
                .req_wren     (tx_v_req_wren[i]             ),
                .req_addr     (tx_req_addr[i]               ),
                .req_wdata    (tx_req_wdata[i]              ),
                .ack_rdata    (tx_ack_rdata[i]              ),
                .mem_req_vld  (tx_mem_req_vld[i]            ),
                .mem_req_wren (tx_mem_req_wren[i]           ),
                .mem_req_addr (tx_mem_req_addr[i]           ),
                .mem_req_wdata(tx_mem_req_wdata[i]          ),
                .mem_ack_rdata(tx_mem_ack_rdata[i]          )
            );
        end
    endgenerate 

endmodule