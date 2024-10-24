module toy_fetch_queue
    import toy_pack::*;
    #(
        parameter int unsigned DEPTH = 128
    )(
        input  logic                                       clk,
        input  logic                                       rst_n,

        input  logic                                       cancel_en,

        output logic                                       filter_rdy,
        input  logic                                       filter_vld,
        input  fetch_queue_pkg                             filter_pld   [FILTER_CHANNEL-1:0],
        input  logic           [FILTER_CHANNEL-1:0]        filter_en,

        output logic           [INST_READ_CHANNEL-1:0]     v_ack_vld,
        input  logic           [INST_READ_CHANNEL-1:0]     v_ack_rdy,
        output logic           [ADDR_WIDTH-1:0]            v_ack_pc              [INST_READ_CHANNEL-1:0],
        output logic           [INST_WIDTH_32-1:0]         v_ack_pld             [INST_READ_CHANNEL-1:0],
        output logic           [INST_IDX_WIDTH-1:0]        v_ack_idx             [INST_READ_CHANNEL-1:0],
        output fe_bypass_pkg                               v_fe_pld              [INST_READ_CHANNEL-1:0],

        input  logic                                       commit_credit_rel_en,
        input  logic           [2:0]                       commit_credit_rel_num
    );

    localparam  int unsigned CRDT_CNT_WIDTH   = $clog2(DEPTH);
    localparam  int unsigned WRITE_NUM_WIDTH  = $clog2(FILTER_CHANNEL);
    localparam  int unsigned FQ_PTR_WIDTH     = $clog2(DEPTH);

    logic           [CRDT_CNT_WIDTH:0]            crdt_cnt;
    logic           [CRDT_CNT_WIDTH:0]            crdt_cal;
    logic           [CRDT_CNT_WIDTH:0]            crdt_sub;
    logic           [CRDT_CNT_WIDTH:0]            crdt_add;
    logic           [CRDT_CNT_WIDTH:0]            crdt_residue;
    logic           [WRITE_NUM_WIDTH:0]           v_write_num           [FILTER_CHANNEL-1:0];
    logic           [WRITE_NUM_WIDTH:0]           v_read_num            [INST_READ_CHANNEL-1:0];
    fetch_queue_pkg                               queue_entry           [DEPTH-1:0];
    logic           [FQ_PTR_WIDTH:0]              wr_ptr;
    logic           [FQ_PTR_WIDTH:0]              rd_ptr;
    logic           [FQ_PTR_WIDTH:0]              wr_add_ptr            [FILTER_CHANNEL-1:0];
    logic           [FQ_PTR_WIDTH:0]              rd_add_ptr            [INST_READ_CHANNEL-1:0];
    logic                                         wren;
    logic                                         rden;

    logic           [INST_READ_CHANNEL-1:0]       v_fq_rdy;
    logic           [INST_READ_CHANNEL-1:0]       v_fq_vld;

    logic           [$clog2(COMMIT_QUEUE_DEPTH):0]commit_credit_cnt;
    logic                                         commit_credit_can_use;
    logic           [$clog2(COMMIT_QUEUE_DEPTH):0]commit_credit_sub;
    logic           [INST_READ_CHANNEL-1  :0]     v_instruction_en;
    logic           [INST_IDX_WIDTH-1     :0]     instruction_idx_reg;

    //===========================================================================
    // for commit queue
    //===========================================================================
    assign v_ack_vld             = v_fq_vld & {INST_READ_CHANNEL{commit_credit_can_use}};
    assign v_fq_rdy              = v_ack_rdy & {INST_READ_CHANNEL{commit_credit_can_use}};
    assign v_instruction_en      = v_ack_vld & v_ack_rdy;
    assign commit_credit_can_use = (commit_credit_cnt > 8);

    assign commit_credit_sub = v_instruction_en[0] + v_instruction_en[1] + v_instruction_en[2] + v_instruction_en[3] +
                               v_instruction_en[4] + v_instruction_en[5] + v_instruction_en[6] + v_instruction_en[7];
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            commit_credit_cnt <= COMMIT_QUEUE_DEPTH;
        end
        else if(cancel_en)begin
            commit_credit_cnt <= COMMIT_QUEUE_DEPTH;
        end
        else if(|v_instruction_en | commit_credit_rel_en)begin
            commit_credit_cnt <= commit_credit_cnt + ($clog2(COMMIT_QUEUE_DEPTH)'(commit_credit_rel_num)) - commit_credit_sub ;
        end
    end

    generate
        for(genvar i = 0;i < INST_READ_CHANNEL;i = i + 1)begin :READ_CHANNLE_GEN
            if(i==0)begin : READ_CHANNLE_0_GEN
                always_comb begin
                    if(v_instruction_en[i])begin
                        v_ack_idx[i] = instruction_idx_reg + 1;
                    end
                    else begin
                        v_ack_idx[i] = instruction_idx_reg;
                    end
                end
            end
            else begin : READ_CHANNLE_NEQ0_GEN
                always_comb begin
                    if(v_instruction_en[i])begin
                        v_ack_idx[i] = v_ack_idx[i-1] + 1;
                    end
                    else begin
                        v_ack_idx[i] = v_ack_idx[i-1];
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            instruction_idx_reg <= 0-1;
        end
        else if(cancel_en)begin
            instruction_idx_reg <= 0-1;

        end
        else if(|v_instruction_en)begin
            instruction_idx_reg <= v_ack_idx[INST_READ_CHANNEL-1] ;
        end
    end

    //===========================================================================
    // fetch queue
    //===========================================================================
    // write num
    assign filter_rdy = crdt_residue >= FILTER_CHANNEL;

    generate
        for (genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_WR
            if (i==0)   assign v_write_num[i] = filter_en[i];
            else        assign v_write_num[i] = filter_en[i] + v_write_num[i-1];
        end
    endgenerate

    // read num
    generate
        for(genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_RD
            assign v_fq_vld[i] = (crdt_cnt>i);
            if(i==0)    assign v_read_num[i] = v_fq_vld[i]&&v_fq_rdy[i];
            else        assign v_read_num[i] = (v_fq_vld[i]&&v_fq_rdy[i]) + v_read_num[i-1];
        end
    endgenerate

    generate
        for (genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_RD_ENTRY
            assign rd_add_ptr[i]        = rd_ptr + i;
            assign v_ack_pld[i]         = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].inst;
            assign v_ack_pc[i]          = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.pc;
            assign v_fe_pld[i].pred_pc  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.pred_pc;
            assign v_fe_pld[i].tgt_pc   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.tgt_pc;
            assign v_fe_pld[i].offset   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.offset;
            assign v_fe_pld[i].is_cext  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.is_cext;
            assign v_fe_pld[i].carry    = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.carry;
            assign v_fe_pld[i].inst_pld = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].inst;
            assign v_fe_pld[i].is_call  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.is_call; // for test
            assign v_fe_pld[i].is_ret   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.is_ret;
            assign v_fe_pld[i].taken    = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.taken;
        end
    endgenerate

    // credit counter
    assign crdt_residue = DEPTH - crdt_cnt;
    assign crdt_add     = v_write_num[FILTER_CHANNEL-1] & {(WRITE_NUM_WIDTH+1){wren}};
    assign crdt_sub     = v_read_num[INST_READ_CHANNEL-1] & {(WRITE_NUM_WIDTH+1){rden}};
    assign crdt_cal     =  crdt_add - crdt_sub;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)              crdt_cnt <= {CRDT_CNT_WIDTH{1'b0}};
        else if(cancel_en)      crdt_cnt <= {CRDT_CNT_WIDTH{1'b0}};
        else if(wren|rden)      crdt_cnt <= crdt_cnt + crdt_cal;
    end

    // pointer
    assign wren = filter_rdy && filter_vld;
    assign rden = |(v_fq_vld|v_fq_rdy);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          wr_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(cancel_en)  wr_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(wren)       wr_ptr <= wr_ptr + v_write_num[FILTER_CHANNEL-1];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          rd_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(cancel_en)  rd_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(rden)       rd_ptr <= rd_ptr + v_read_num[INST_READ_CHANNEL-1];
    end

    // write queue entry
    generate
        for (genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_WR_PTR
            assign wr_add_ptr[i] = wr_ptr + i;
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int i = 0; i < FILTER_CHANNEL; i=i+1) begin
            if(wren&&filter_en[i])  queue_entry[wr_add_ptr[i][FQ_PTR_WIDTH-1:0]] <= filter_pld[i];
        end
    end




// `ifdef TOY_SIM
//     initial begin
//         forever begin
//             @(posedge clk)
//                 $display("fetch queue is filter_rdy:[%h], filter_vld:[%h]", filter_rdy, filter_vld);
//                 $display("fetch queue is v_fq_vld:[%h], v_fq_rdy:[%h]", v_fq_vld, v_fq_rdy);
//         end
//     end
// `endif

endmodule 