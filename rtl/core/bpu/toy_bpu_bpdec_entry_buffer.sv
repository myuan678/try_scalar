module toy_bpu_bpdec_entry_buffer
    import toy_pack::*;
    (
        input  logic                                         clk,
        input  logic                                         rst_n,
        input  logic                                         be_flush,
        input  logic                                         ras_flush,
        input  logic                                         bp2_flush,

        input  logic                                           s_vld_s0,
        output logic                                           s_rdy_s0,
        output btb_entry_buffer_pkg                            s_pld_s0 [ENTRY_BUFFER_NUM-1:0],
        output logic                [ENTRY_BUFFER_PTR_WIDTH:0] s_ptr_s0,
        output logic                [ENTRY_BUFFER_NUM-1:0]     s_ena_s0,
        input  logic                                           s_vld_s1,
        input  entry_buffer_pkg                                s_pld_s1,

        input  logic                                         s_update_vld,
        input  bpu_update_pkg                                s_update_pld,
        input  logic                                         s_update_enqueue,

        output logic                                         m_vld,
        input  logic                                         m_rdy,
        output entry_buffer_pkg                              m_pld
    );

    localparam BDepth = $clog2(BTB_WAY_NUM);

    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   wr_ptr;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   rd_ptr;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   tn_ptr;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   eq_ptr;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   tn_ptr_res;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   eq_ptr_res;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   credit_cnt;
    logic              [ENTRY_BUFFER_PTR_WIDTH:0]   credit_cal;
    logic                                           credit_add;
    logic                                           credit_sub;
    logic                                           wren;
    logic                                           rden;

    logic                 [ADDR_WIDTH-1:0]          entry_buffer_pred_pc     [ENTRY_BUFFER_NUM-1:0];
    tage_entry_pkg                                  entry_buffer_tage        [ENTRY_BUFFER_NUM-1:0];
    tage_update_pkg                                 entry_buffer_tage_update [ENTRY_BUFFER_NUM-1:0];
    btb_entry_buffer_pkg                            entry_buffer_btb         [ENTRY_BUFFER_NUM-1:0];

    logic              [TAGE_BASE_INDEX_WIDTH-1:0]  bypass_tb_idx;
    logic              [TAGE_BASE_PRED_WIDTH-1:0]   bypass_tb_pred;
    logic                                           bypass_tb_add;
    logic                                           bypass_tb_sub;

    btb_entry_buffer_pkg                            btb_entry_update;
    logic                [BTB_WAY_NUM-2:0]          btb_node_update;

    tage_update_pkg                                 tage_alloc_update                ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_alloc_id                    ;
    logic                                           tage_update_en                   ;
    logic                                           tage_update_mispred              ;
    tage_entry_pkg                                  tage_update_entry                ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_prob                 ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_alloc_vld            ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_alloc_vld_prob       ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_alloc_decay          ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_alloc_id             ;
    logic              [TAGE_TABLE_NUM-1:0]         tage_update_alloc_id_prob        ;
    logic                                           tage_update_alloc_id_prob_vld    ;
    logic                                           tage_update_alloc_id_vld_dummy   ;
    logic              [$clog2(TAGE_TABLE_NUM)-1:0] tage_update_alloc_bin_prob_dummy ;
    logic              [$clog2(TAGE_TABLE_NUM)-1:0] tage_update_alloc_bin_dummy      ;

    btb_entry_buffer_pkg                            btb_update_entry    ;
    logic                                           btb_update_en       ;
    logic                [BTB_WAY_NUM-1:0]          btb_update_way_vld  ;
    logic                [BTB_WAY_NUM-1:0]          btb_update_way_hit  ;
    logic                [BTB_WAY_NUM-2:0]          btb_update_node     ;
    logic                [BTB_WAY_NUM-1:0]          btb_update_vv_matrix [BTB_WAY_NUM-1:0];
    logic                [BTB_WAY_NUM-1:0]          btb_update_arb_vld  ;
    logic                [BTB_WAY_NUM-1:0]          btb_update_arb_hit  ;
    
    logic                [ENTRY_BUFFER_NUM-1:0]     bypass_en;


    assign s_rdy_s0                         = ((ENTRY_BUFFER_NUM - 1) > credit_cnt);
    assign m_vld                            = ~(tn_ptr == rd_ptr);
    assign m_pld.pred_pc                    = entry_buffer_pred_pc[rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];
    assign m_pld.tage_entry.entry           = entry_buffer_tage[rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];
    assign m_pld.tage_entry.update          = entry_buffer_tage_update[rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];
    assign m_pld.btb_entry                  = entry_buffer_btb[rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];

    assign s_pld_s0 = entry_buffer_btb;
    assign s_ptr_s0 = tn_ptr;
    assign s_ena_s0 = bypass_en;

    //===============================================
    //  credit counter and pointer
    //===============================================
    // credit counter
    assign credit_add                       = s_vld_s0 && s_rdy_s0;
    assign credit_sub                       = m_vld && m_rdy;
    assign credit_cal                       = credit_add - credit_sub;
    assign tn_ptr_res                       = ({1'b1, tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]} - {1'b0, rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]}) + 2'b10;
    assign eq_ptr_res                       = ({1'b1, eq_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]} - {1'b0, rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]}) + 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         credit_cnt <= {ENTRY_BUFFER_PTR_WIDTH{1'b0}};
        else if(be_flush)                   credit_cnt <= tn_ptr_res[ENTRY_BUFFER_PTR_WIDTH-1:0];
        else if(ras_flush)                  credit_cnt <= eq_ptr_res[ENTRY_BUFFER_PTR_WIDTH-1:0];
        else if(credit_add|credit_sub)      credit_cnt <= credit_cnt + credit_cal;
    end

    // for pointer
    // assign wren         = s_vld_s1 && ~bp2_flush;
    assign wren                             = s_vld_s1;
    assign rden                             = m_vld && m_rdy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         wr_ptr <= {(ENTRY_BUFFER_PTR_WIDTH+1){1'b0}};
        else if(be_flush)                   wr_ptr <= tn_ptr + 1'b1;
        else if(ras_flush)                  wr_ptr <= eq_ptr + 1'b1;
        else if(wren)                       wr_ptr <= wr_ptr + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         rd_ptr  <= {(ENTRY_BUFFER_PTR_WIDTH+1){1'b0}};
        else if(rden)                       rd_ptr  <= rd_ptr + 1'b1;
    end

    // for commit
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         tn_ptr <= {(ENTRY_BUFFER_PTR_WIDTH+1){1'b0}};
        else if(s_update_vld)               tn_ptr <= tn_ptr + 1'b1;
    end

    // for enqueue
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                         eq_ptr  <= {(ENTRY_BUFFER_PTR_WIDTH+1){1'b0}};
        else if(be_flush)                   eq_ptr  <= tn_ptr + 1'b1;
        else if(s_update_enqueue)           eq_ptr  <= eq_ptr + 1'b1;
    end

    //===============================================
    //  bypass enable
    //===============================================
    generate
        for (genvar i=0; i< ENTRY_BUFFER_NUM; i = i + 1) begin: GEN_BYPASS
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n) begin
                    bypass_en[i] <= 1'b0;
                end
                else if((rd_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==i) && rden) begin
                    bypass_en[i] <= 1'b0;
                end
                else if((tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==i) && s_update_vld) begin
                    bypass_en[i] <= 1'b1;
                end
            end
        end
    endgenerate

    //===============================================
    //  pred update
    //===============================================
    // tage base table bypass
    assign bypass_tb_idx                     = m_pld.tage_entry.entry.tb_idx;
    assign bypass_tb_pred                    = m_pld.tage_entry.entry.tb_pred;
    assign bypass_tb_add                     = m_pld.tage_entry.update.tb_pred_add;
    assign bypass_tb_sub                     = m_pld.tage_entry.update.tb_pred_sub;

    // btb read node update
    assign btb_entry_update.entry.node       = btb_node_update;
    assign btb_entry_update.tag              = s_pld_s1.btb_entry.tag;
    assign btb_entry_update.index            = s_pld_s1.btb_entry.index;
    assign btb_entry_update.entry.entry_way  = s_pld_s1.btb_entry.entry.entry_way;
    assign btb_entry_update.way_hit          = s_pld_s1.btb_entry.way_hit;
    assign btb_entry_update.real_taken       = |s_pld_s1.btb_entry.way_hit;

    generate
        for(genvar i = 0; i < BDepth; i=i+1) begin: level_rd
            for(genvar j = 0;j < 2**i;j=j+1) begin: offset_rd
                if(i==BDepth-1) begin
                    assign btb_node_update[2**i+j-1] = s_vld_s1 ? (s_pld_s1.btb_entry.entry.node[2**i+j-1]||s_pld_s1.btb_entry.way_hit[2*j])&&~s_pld_s1.btb_entry.way_hit[2*j+1] : s_pld_s1.btb_entry.entry.node[2**i+j-1];
                end
                else begin
                    assign btb_node_update[2**i+j-1] = s_vld_s1 ? (s_pld_s1.btb_entry.entry.node[2**i+j-1]||(|s_pld_s1.btb_entry.way_hit[j*2**(BDepth-i)+2**(BDepth-i-1)-1:j*2**(BDepth-i)]))&&~(|s_pld_s1.btb_entry.way_hit[(j+1)*2**(BDepth-i)-1:j*2**(BDepth-i)+2**(BDepth-i-1)]) :
                    s_pld_s1.btb_entry.entry.node[2**i+j-1];
                end
            end
        end
    endgenerate

    //===============================================
    //  commit update
    //===============================================
    cmn_lfsr4 u_prob(
        .clk  (clk                          ),
        .rst_n(rst_n                        ),
        .out  (tage_update_prob             )
    ); // just need one

    // for tage update
    assign tage_update_entry                = entry_buffer_tage[tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];
    assign tage_update_mispred              = s_update_pld.taken_err;
    assign tage_alloc_update.taken          = s_update_pld.taken;
    assign tage_alloc_update.mispred        = tage_update_mispred;
    assign tage_alloc_update.alloc_id       = tage_alloc_id & {TAGE_TABLE_NUM{tage_update_mispred}};
    assign tage_alloc_update.tb_pred_add    = tage_update_entry.prvd_idx[0] && s_update_pld.taken;
    assign tage_alloc_update.tb_pred_sub    = tage_update_entry.prvd_idx[0] && ~s_update_pld.taken;
    assign tage_update_en                   = s_update_vld;

    // tage allocate
    for (genvar i = 0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_ALLOC
        assign tage_update_alloc_vld[i]         = (|tage_update_entry.prvd_idx[i+1:0]) & ~(tage_update_entry.prvd_idx[i+1]) && tage_update_entry.tx_entry[i].u_cnt==0;
        assign tage_update_alloc_decay[i]       = (|tage_update_alloc_vld) & (|tage_update_entry.prvd_idx[i+1:0]) & ~(tage_update_entry.prvd_idx[i+1]) && tage_update_entry.tx_entry[i].u_cnt!=0;
    end

    assign tage_update_alloc_vld_prob = (|(tage_update_alloc_vld & tage_update_prob)) ? (tage_update_alloc_vld & tage_update_prob) : tage_update_alloc_vld;
    assign tage_alloc_id              = tage_update_alloc_id_prob_vld                 ? tage_update_alloc_id_prob                  : tage_update_alloc_id;

    cmn_lead_one #(
        .ENTRY_NUM(4                                        )
    ) u_prob_alloc(
        .v_entry_vld   (tage_update_alloc_vld_prob          ),
        .v_free_idx_oh (tage_update_alloc_id_prob           ),
        .v_free_vld    (tage_update_alloc_id_prob_vld       ),
        .v_free_idx_bin(tage_update_alloc_bin_prob_dummy    )
    );

    cmn_lead_one #(
        .ENTRY_NUM(4)
    ) u_alloc(
        .v_entry_vld   (tage_update_alloc_vld               ),
        .v_free_idx_oh (tage_update_alloc_id                ),
        .v_free_vld    (tage_update_alloc_id_vld_dummy      ),
        .v_free_idx_bin(tage_update_alloc_bin_dummy         )
    );

    // btb update
    assign btb_update_entry    = entry_buffer_btb[tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]];
    assign btb_update_way_hit  = btb_update_entry.way_hit;
    assign btb_update_arb_vld  = |btb_update_way_hit ? btb_update_way_hit : (&btb_update_way_vld ? {BTB_WAY_NUM{1'b1}} : ~btb_update_way_vld);
    assign btb_update_en       = s_update_vld && s_update_pld.taken;

    for (genvar i = 0; i < BTB_WAY_NUM; i=i+1) begin
        assign btb_update_way_vld[i] = btb_update_entry.entry.entry_way[i].valid;
    end

    cmn_tree_plru_comb #(
        .WIDTH(BTB_WAY_NUM                                  )
    ) u_wr_plru (
        .alloc_en   (btb_update_en                          ),
        .node       (btb_update_entry.entry.node            ),
        .v_alloc    (btb_update_arb_hit                     ),
        .update_node(btb_update_node                        ),
        .vv_matrix  (btb_update_vv_matrix                   )
    );

    cmn_arb_vr_matrix #(
        .WIDTH(BTB_WAY_NUM                                  )
    ) u_arb (
        .vv_matrix(btb_update_vv_matrix                     ),
        .v_vld_s  (btb_update_arb_vld                       ),
        .v_rdy_s  (btb_update_arb_hit                       ),
        .vld_m    (                                         ),
        .rdy_m    (btb_update_en                            )
    );


    //===============================================
    //  write entry buffer
    //===============================================
    // for assertion
    always_ff @(posedge clk) begin
        if (wren)       entry_buffer_pred_pc[wr_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]] <= s_pld_s1.pred_pc;

    end

    // for tage part
    always_ff @(posedge clk) begin
        if(s_update_vld)  entry_buffer_tage_update[tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]] <= tage_alloc_update;
    end

    generate
        for(genvar n=0; n < ENTRY_BUFFER_NUM; n=n+1) begin: GEN_ENTRY_TAGE_UPDT
            always_ff @(posedge clk) begin
                if (wren && wr_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==n)
                    entry_buffer_tage[n] <= s_pld_s1.tage_entry.entry;
                else if(s_update_vld && (tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==n)) begin
                    for (int i = 0; i < TAGE_TABLE_NUM+1; i = i + 1) begin
                        if (i == 0) begin
                            if (tage_update_entry.prvd_idx[0]) begin
                                // pred update
                                if (~s_update_pld.taken) begin
                                    if(rden && (tage_update_entry.tb_idx==bypass_tb_idx) && bypass_tb_pred > 0)
                                        entry_buffer_tage[n].tb_pred <= bypass_tb_pred - 1'b1;
                                    else if(tage_update_entry.tb_pred > 0)
                                        entry_buffer_tage[n].tb_pred <= tage_update_entry.tb_pred - 1'b1;
                                end
                                else if (s_update_pld.taken && tage_update_entry.tb_pred < {TAGE_BASE_PRED_WIDTH{1'b1}}) begin
                                    if(rden && (tage_update_entry.tb_idx==bypass_tb_idx) && bypass_tb_pred < {TAGE_BASE_PRED_WIDTH{1'b1}})
                                        entry_buffer_tage[n].tb_pred <= bypass_tb_pred + 1'b1;
                                    else if(tage_update_entry.tb_pred < {TAGE_BASE_PRED_WIDTH{1'b1}})
                                        entry_buffer_tage[n].tb_pred <= tage_update_entry.tb_pred + 1'b1;
                                end
                            end
                        end
                        else begin
                            if (tage_update_entry.prvd_idx[i]) begin
                                // pred update
                                if (~s_update_pld.taken && tage_update_entry.tx_entry[i-1].pred_cnt > 0) begin
                                    entry_buffer_tage[n].tx_entry[i-1].pred_cnt <= tage_update_entry.tx_entry[i-1].pred_cnt - 1'b1;
                                end
                                else if (s_update_pld.taken && tage_update_entry.tx_entry[i-1].pred_cnt < {TAGE_TX_PRED_WIDTH{1'b1}}) begin
                                    entry_buffer_tage[n].tx_entry[i-1].pred_cnt <= tage_update_entry.tx_entry[i-1].pred_cnt + 1'b1;
                                end
                                // u update
                                if (tage_update_mispred && tage_update_entry.pred_diff && tage_update_entry.tx_entry[i-1].u_cnt > 0) begin
                                    entry_buffer_tage[n].tx_entry[i-1].u_cnt <= tage_update_entry.tx_entry[i-1].u_cnt - 1'b1;
                                end
                                else if (~tage_update_mispred && tage_update_entry.pred_diff && tage_update_entry.tx_entry[i-1].u_cnt < {TAGE_TX_USEFUL_WIDTH{1'b1}}) begin
                                    entry_buffer_tage[n].tx_entry[i-1].u_cnt <= tage_update_entry.tx_entry[i-1].u_cnt + 1'b1;
                                end
                            end
                            // u decay
                            else if (tage_update_mispred && tage_update_alloc_decay[i-1] && tage_update_en) begin
                                entry_buffer_tage[n].tx_entry[i-1].u_cnt <= tage_update_entry.tx_entry[i-1].u_cnt - 1'b1;
                            end
                        end
                    end
                end
                else if(rden && (entry_buffer_tage[n].tb_idx==bypass_tb_idx)) begin
                    if(bypass_tb_add && entry_buffer_tage[n].tb_pred < {TAGE_BASE_PRED_WIDTH{1'b1}})
                        entry_buffer_tage[n].tb_pred <= bypass_tb_pred + 1'b1;
                    else if(bypass_tb_sub && entry_buffer_tage[n].tb_pred > 0)
                        entry_buffer_tage[n].tb_pred <= bypass_tb_pred - 1'b1;
                end
            end
        end
    endgenerate

    // for btb part
    generate
        for(genvar n=0; n < ENTRY_BUFFER_NUM; n=n+1) begin: GEN_BTB_ENTRY_UPDT
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    entry_buffer_btb[n] <= {($bits(btb_entry_buffer_pkg)){1'b0}};
                end
                else if (wren && wr_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==n) begin
                    entry_buffer_btb[n] <= btb_entry_update;
                end
                // for commit and cancel
                else if (btb_update_en && tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]==n) begin
                    entry_buffer_btb[n].entry.node <= btb_update_node;
                    entry_buffer_btb[n].way_hit    <= btb_update_arb_hit;
                    entry_buffer_btb[n].real_taken <= s_update_pld.taken;

                    for (int i = 0; i < BTB_WAY_NUM; i = i + 1) begin
                        if(btb_update_arb_hit[i]&&btb_update_en) begin
                            entry_buffer_btb[n].entry.entry_way[i].valid   <= 1'b1;
                            entry_buffer_btb[n].entry.entry_way[i].tag     <= entry_buffer_btb[n].tag;
                            entry_buffer_btb[n].entry.entry_way[i].tgt_pc  <= s_update_pld.tgt_pc;
                            entry_buffer_btb[n].entry.entry_way[i].offset  <= s_update_pld.offset;
                            entry_buffer_btb[n].entry.entry_way[i].is_cext <= s_update_pld.is_cext;
                            entry_buffer_btb[n].entry.entry_way[i].carry   <= s_update_pld.carry;
                        end
                    end
                end
            end
        end
    endgenerate



`ifdef TOY_SIM
    logic [63:0]  update_cnt;
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)  update_cnt             <= 0;
        else if(m_vld && m_rdy) update_cnt <= update_cnt + 1'b1;
    end
    logic [63:0] real_commit;
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)  real_commit             <= 0;
        else if(s_update_vld) real_commit   <= update_cnt + 1;
    end


    logic [63:0] cycle;
    assign cycle = u_toy_scalar.u_core.u_toy_commit.cycle;

    initial begin
        forever begin
            @(posedge clk)
                if(s_update_vld) begin
                    if(s_update_pld.pred_pc != entry_buffer_pred_pc[tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]]) begin
                        $display("Entry Buffer Error Detect: [pc=%h][pc_update=%h][cycle=%0d]", entry_buffer_pred_pc[tn_ptr[ENTRY_BUFFER_PTR_WIDTH-1:0]], s_update_pld.pred_pc, cycle);
                    end
                end
        end
    end

`endif

endmodule