module toy_fe_commt_buffer
    import toy_pack::*;
    (
        input    logic                          clk,
        input    logic                          rst_n,

        input    logic  [COMMIT_CHANNEL-1:0]    be_commit_vld,
        output   logic                          be_commit_rdy,
        input    be_pkg                         be_commit_pld  [COMMIT_CHANNEL-1:0],
        input    logic  [COMMIT_CHANNEL-1:0]    be_cancel_en,
        input    logic                          be_cancel_edge,
        input    be_pkg                         be_cancel_pld,

        output   logic                          fe_cancel_vld,
        output   logic                          fe_cancel_pend,
        output   be_pkg                         fe_commit_pld,
        output   logic                          fe_commit_vld

    );
    localparam PTR_WIDTH = $clog2(COMMIT_BUFFER_DEPTH);

    be_pkg                               v_commit_pld      [COMMIT_CHANNEL-1:0];
    logic   [COMMIT_CHANNEL-1:0]         v_commit_vld      [COMMIT_CHANNEL-1:0];
    logic   [COMMIT_CHANNEL-1:0]         v_commit_oh       [COMMIT_CHANNEL-1:0];
    logic   [$clog2(COMMIT_CHANNEL)-1:0] v_commit_bin      [COMMIT_CHANNEL-1:0];
    logic   [COMMIT_CHANNEL-1:0]         v_commit_dummy;
    logic   [COMMIT_CHANNEL-1:0]         v_commit_chnl_vld;
    logic   [COMMIT_CHANNEL-1:0]         v_cancel_chnl_vld;
    logic   [COMMIT_CHANNEL-1:0]         commit_chnl_en;
    logic   [$clog2(COMMIT_CHANNEL):0]   commit_num        [COMMIT_CHANNEL-1:0];
    logic   [COMMIT_CHANNEL-1:0]         v_cancel_en;

    be_pkg                               pending_buffer;
    logic                                pending_flag;
    logic                                pending_cancel;
    logic                                pending_commit;
    be_pkg                               pending_update;
    logic                                is_pending_taken;
    logic   [COMMIT_CHANNEL-1:0]         v_update_chnl_vld;
    be_pkg                               v_update_pld      [COMMIT_CHANNEL-1:0];
    be_pkg                               commit_nxt_pld;


    logic   [PTR_WIDTH:0]                rd_ptr;
    logic   [PTR_WIDTH:0]                wr_ptr;
    logic   [PTR_WIDTH:0]                v_wr_ptr       [COMMIT_CHANNEL-1:0];
    be_pkg                               commit_buffer  [COMMIT_BUFFER_DEPTH-1:0];
    logic   [1:0]                        cancel_buffer  [COMMIT_BUFFER_DEPTH-1:0];  // bit 0: cancel, bit 1: pend_cancel
    logic                                rden;
    logic                                wren;
    logic                                buf_empty;
    logic                                buf_full;

    //================================================================
    // for update buffer
    //================================================================
    // pending case
    assign pending_cancel = be_cancel_edge&&be_cancel_pld.taken_pend;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                   pending_flag <= 1'b0;
        else if(pending_cancel)       pending_flag <= 1'b1;
        else if(v_commit_chnl_vld[0]) pending_flag <= 1'b0;
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if (~rst_n)                   pending_buffer <= {$bits(be_pkg){1'b0}};
        else if(pending_cancel)       pending_buffer <= be_cancel_pld;
    end

    // TODO: cext
    assign pending_commit                = pending_flag && (|v_commit_chnl_vld || pending_cancel);
    assign commit_nxt_pld                = |v_commit_chnl_vld ? v_commit_pld[0] : be_cancel_pld;
    assign is_pending_taken              = (pending_buffer.bypass.offset + commit_nxt_pld.bypass.offset) <= (PRED_BLOCK_LEN-2);
    assign pending_update.pc             = pending_buffer.pc;
    assign pending_update.is_call        = 1'b0;
    assign pending_update.is_ret         = 1'b0;
    assign pending_update.taken_err      = 1'b1;
    assign pending_update.taken_pend     = 1'b0;
    assign pending_update.bypass.carry   = commit_nxt_pld.bypass.carry;
    assign pending_update.bypass.is_cext = commit_nxt_pld.bypass.is_cext;
    assign pending_update.bypass.taken   = is_pending_taken;
    assign pending_update.bypass.offset  = is_pending_taken ? pending_buffer.bypass.offset + commit_nxt_pld.bypass.offset + 1'b1 : (PRED_BLOCK_LEN-1);
    assign pending_update.bypass.tgt_pc  = is_pending_taken ? commit_nxt_pld.bypass.tgt_pc                                       : pending_buffer.bypass.pred_pc + (PRED_BLOCK_LEN<<2);
    assign pending_update.bypass.pred_pc = pending_buffer.bypass.pred_pc;

    generate
        for (genvar i=0; i < COMMIT_CHANNEL; i=i+1) begin: GEN_UPDATE
            if (i==0)  begin
                assign v_update_chnl_vld[i] = pending_commit ? pending_commit : v_commit_chnl_vld[i];
                assign v_update_pld[i]      = pending_commit ? pending_update : v_commit_pld[i];
                assign v_cancel_chnl_vld[i] = pending_commit ? 1'b0           : v_cancel_en[i];
            end
            else begin
                assign v_update_chnl_vld[i] = pending_commit ? v_commit_chnl_vld[i-1] : v_commit_chnl_vld[i];
                assign v_update_pld[i]      = pending_commit ? v_commit_pld[i-1]      : v_commit_pld[i];
                assign v_cancel_chnl_vld[i] = pending_commit ? v_cancel_en[i-1]       : v_cancel_en[i];
            end
        end
    endgenerate

    // commit channel process
    generate
        for (genvar i = 0; i < COMMIT_CHANNEL; i=i+1) begin: GEN_CMT_I
            assign commit_chnl_en[i] = be_commit_pld[i].is_last && be_commit_vld[i];
            assign v_cancel_en[i]    = (commit_num[COMMIT_CHANNEL-1] == (i+1)) && be_cancel_edge;

            if (i==0)      assign commit_num[i] = commit_chnl_en[i];
            else           assign commit_num[i] = commit_chnl_en[i] + commit_num[i-1];

            for (genvar j = 0; j < COMMIT_CHANNEL; j=j+1) begin: GEN_CMT_O
                if(i<=j)    assign v_commit_vld[i][j] = (commit_num[j] == (i+1));
                else        assign v_commit_vld[i][j] = 1'b0;
            end

        end
    endgenerate

    generate
        for (genvar i = 0; i < COMMIT_CHANNEL; i=i+1) begin: GEN_CMT_PLD
            assign v_commit_chnl_vld[i] = |v_commit_vld[i];

            cmn_lead_one #(
                .ENTRY_NUM(COMMIT_CHANNEL)
            ) u_lead_one (
                .v_entry_vld   (v_commit_vld[i]  ),
                .v_free_idx_oh (v_commit_oh[i]   ),
                .v_free_idx_bin(v_commit_bin[i]  ),
                .v_free_vld    (v_commit_dummy[i])
            );

            cmn_real_mux_onehot #(
                .WIDTH    (COMMIT_CHANNEL),
                .PLD_WIDTH($bits(be_pkg) )
            ) u_select (
                .select_onehot(v_commit_oh[i] ),
                .v_pld        (be_commit_pld  ),
                .select_pld   (v_commit_pld[i])
            );
        end
    endgenerate

    // commit buffer pointer
    assign buf_empty     = wr_ptr == rd_ptr;
    assign buf_full      = {~wr_ptr[PTR_WIDTH], wr_ptr[PTR_WIDTH-1:0]} == rd_ptr;
    assign be_commit_rdy = 1'b1;
    assign wren          = be_commit_rdy && |v_update_chnl_vld;
    assign rden          = !buf_empty;


    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)                              wr_ptr <= {(PTR_WIDTH+1){1'b0}};
        else if(v_update_chnl_vld[3] && wren)   wr_ptr <= wr_ptr + 4;
        else if(v_update_chnl_vld[2] && wren)   wr_ptr <= wr_ptr + 3;
        else if(v_update_chnl_vld[1] && wren)   wr_ptr <= wr_ptr + 2;
        else if(v_update_chnl_vld[0] && wren)   wr_ptr <= wr_ptr + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          rd_ptr <= {(PTR_WIDTH+1){1'b0}};
        else if(rden)                       rd_ptr <= rd_ptr + 1;
    end

    generate
        for(genvar i=0; i < COMMIT_CHANNEL; i=i+1) begin: GEN_CHNL
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)                              v_wr_ptr[i] <= i;
                else if(v_update_chnl_vld[3] && wren)   v_wr_ptr[i] <= wr_ptr + 4 + i;
                else if(v_update_chnl_vld[2] && wren)   v_wr_ptr[i] <= wr_ptr + 3 + i;
                else if(v_update_chnl_vld[1] && wren)   v_wr_ptr[i] <= wr_ptr + 2 + i;
                else if(v_update_chnl_vld[0] && wren)   v_wr_ptr[i] <= wr_ptr + 1 + i;
            end
        end
    endgenerate

    // for commit buffer output
    assign fe_cancel_vld   = cancel_buffer[rd_ptr[PTR_WIDTH-1:0]][0];
    assign fe_cancel_pend  = cancel_buffer[rd_ptr[PTR_WIDTH-1:0]][1];
    assign fe_commit_pld   = commit_buffer[rd_ptr[PTR_WIDTH-1:0]];
    assign fe_commit_vld   = rden;

    generate
        for(genvar i=0; i < COMMIT_BUFFER_DEPTH; i=i+1) begin: GEN_BUF
            always @(posedge clk) begin
                if     (wren && v_update_chnl_vld[0] && (v_wr_ptr[0][PTR_WIDTH-1:0]==i))    commit_buffer[i] <= v_update_pld[0];
                else if(wren && v_update_chnl_vld[1] && (v_wr_ptr[1][PTR_WIDTH-1:0]==i))    commit_buffer[i] <= v_update_pld[1];
                else if(wren && v_update_chnl_vld[2] && (v_wr_ptr[2][PTR_WIDTH-1:0]==i))    commit_buffer[i] <= v_update_pld[2];
                else if(wren && v_update_chnl_vld[3] && (v_wr_ptr[3][PTR_WIDTH-1:0]==i))    commit_buffer[i] <= v_update_pld[3];
            end

            always @(posedge clk or negedge rst_n) begin
                if (~rst_n)                                                               cancel_buffer[i] <= 2'b0;
                else if(rden && rd_ptr[PTR_WIDTH-1:0]==i)                                 cancel_buffer[i] <= 2'b0;
                else if(wren && v_cancel_chnl_vld[0] && v_wr_ptr[0][PTR_WIDTH-1:0]==i)    cancel_buffer[i] <= {pending_cancel, be_cancel_edge};
                else if(wren && v_cancel_chnl_vld[1] && v_wr_ptr[1][PTR_WIDTH-1:0]==i)    cancel_buffer[i] <= {pending_cancel, be_cancel_edge};
                else if(wren && v_cancel_chnl_vld[2] && v_wr_ptr[2][PTR_WIDTH-1:0]==i)    cancel_buffer[i] <= {pending_cancel, be_cancel_edge};
                else if(wren && v_cancel_chnl_vld[3] && v_wr_ptr[3][PTR_WIDTH-1:0]==i)    cancel_buffer[i] <= {pending_cancel, be_cancel_edge};
            end
        end
    endgenerate



endmodule 