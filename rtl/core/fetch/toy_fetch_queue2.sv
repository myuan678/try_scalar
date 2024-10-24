module toy_fetch_queue2
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

    localparam  int unsigned WRITE_NUM_WIDTH  = $clog2(FILTER_CHANNEL);
    localparam  int unsigned READ_NUM_WIDTH   = $clog2(INST_READ_CHANNEL);
    localparam  int unsigned FQ_PTR_WIDTH     = $clog2(INST_READ_CHANNEL);
    localparam  int unsigned FQ_BUF_DEPTH     = DEPTH/INST_READ_CHANNEL;
    localparam  int unsigned FQ_BUF_IN_NUM    = FILTER_CHANNEL/INST_READ_CHANNEL;


    logic           [WRITE_NUM_WIDTH:0]           v_write_num           [FILTER_CHANNEL-1:0];
    logic           [READ_NUM_WIDTH:0]            v_read_num            [INST_READ_CHANNEL-1:0];
    logic           [FQ_PTR_WIDTH:0]              wr_ptr;
    logic           [FQ_PTR_WIDTH:0]              rd_ptr;
    logic           [FQ_PTR_WIDTH-1:0]            wr_add_ptr            [INST_READ_CHANNEL-1:0];
    logic           [FQ_PTR_WIDTH-1:0]            rd_add_ptr            [INST_READ_CHANNEL-1:0];
    logic           [FQ_PTR_WIDTH-1:0]            rd_add_ptr_rev        [INST_READ_CHANNEL-1:0];
    logic                                         wren;
    logic                                         rden;

    logic           [INST_READ_CHANNEL-1:0]       v_fq_rdy;
    logic           [INST_READ_CHANNEL-1:0]       v_fq_vld;
    logic           [INST_READ_CHANNEL-1:0]       v_buf_req_rdy;
    logic           [INST_READ_CHANNEL-1:0]       v_buf_req_vld;
    fetch_queue_pkg                               v_buf_req_pld [INST_READ_CHANNEL-1:0] [FQ_BUF_IN_NUM-1:0];
    logic           [FQ_BUF_IN_NUM-1:0]           v_buf_req_en  [INST_READ_CHANNEL-1:0];
    logic           [INST_READ_CHANNEL-1:0]       v_buf_ack_vld;
    logic           [INST_READ_CHANNEL-1:0]       v_buf_ack_rdy;
    logic           [ADDR_WIDTH-1:0]              v_buf_ack_pc  [INST_READ_CHANNEL-1:0];
    logic           [INST_WIDTH-1:0]              v_buf_ack_pld [INST_READ_CHANNEL-1:0];
    fe_bypass_pkg   [INST_READ_CHANNEL-1:0]       v_buf_fe_pld;
    fetch_queue_pkg                               v_cb_req_pld  [INST_READ_CHANNEL-1:0] [FQ_BUF_IN_NUM-1:0];
    logic           [FQ_BUF_IN_NUM-1:0]           v_cb_req_en   [INST_READ_CHANNEL-1:0];



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
    assign filter_rdy = &v_buf_req_rdy;

    generate
        for (genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_WR
            if (i==0)   assign v_write_num[i] = filter_en[i];
            else        assign v_write_num[i] = filter_en[i] + v_write_num[i-1];
        end
    endgenerate

    // read num
    generate
        for(genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_RD
            if(i==0)    assign v_read_num[i] = v_fq_vld[i]&&v_fq_rdy[i];
            else        assign v_read_num[i] = (v_fq_vld[i]&&v_fq_rdy[i]) + v_read_num[i-1];
        end
    endgenerate

    // pointer
    assign wren = filter_rdy && filter_vld;
    assign rden = |(v_fq_vld&v_fq_rdy);

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

    generate
        for (genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_PRE_PTR
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)          wr_add_ptr[i] <= i;
                else if(cancel_en)  wr_add_ptr[i] <= i;
                else if(wren)       wr_add_ptr[i] <= i[FQ_PTR_WIDTH-1:0] - v_write_num[FILTER_CHANNEL-1][FQ_PTR_WIDTH-1:0] - wr_ptr[FQ_PTR_WIDTH-1:0];
                else                wr_add_ptr[i] <= i - wr_ptr[FQ_PTR_WIDTH-1:0];
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)          rd_add_ptr[i] <= i;
                else if(cancel_en)  rd_add_ptr[i] <= i;
                else if(rden)       rd_add_ptr[i] <= i[FQ_PTR_WIDTH-1:0] - v_read_num[INST_READ_CHANNEL-1][FQ_PTR_WIDTH-1:0] - rd_ptr[FQ_PTR_WIDTH-1:0];
                else                rd_add_ptr[i] <= i - rd_ptr[FQ_PTR_WIDTH-1:0];
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)          rd_add_ptr_rev[i] <= i;
                else if(cancel_en)  rd_add_ptr_rev[i] <= i;
                else if(rden)       rd_add_ptr_rev[i] <= v_read_num[INST_READ_CHANNEL-1][FQ_PTR_WIDTH-1:0] + rd_ptr[FQ_PTR_WIDTH-1:0] + i;
                else                rd_add_ptr_rev[i] <= rd_ptr[FQ_PTR_WIDTH-1:0] + i;
            end
        end
    endgenerate

    // filter 16to8 crossbar
    generate
        for(genvar i=0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_CB_IN
            for (genvar j=0; j < FQ_BUF_IN_NUM; j=j+1) begin: GEN_CB_IN_NUN
                assign v_cb_req_en[i][j]   = filter_en[j*INST_READ_CHANNEL+i];
                assign v_cb_req_pld[i][j]  = filter_pld[j*INST_READ_CHANNEL+i];
            end
            assign v_buf_req_vld[i] = filter_rdy && filter_vld;
            assign v_buf_req_en[i]  = v_cb_req_en[wr_add_ptr[i][FQ_PTR_WIDTH-1:0]];
            assign v_buf_req_pld[i] = v_cb_req_pld[wr_add_ptr[i][FQ_PTR_WIDTH-1:0]];
        end
    endgenerate

    // fq 8to8 crossbar
    generate
        for(genvar i=0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_CB_out
            assign v_fq_vld[i]        = v_buf_ack_vld[rd_add_ptr_rev[i][FQ_PTR_WIDTH-1:0]];
            assign v_buf_ack_rdy[i]   = v_fq_rdy[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]];
            assign v_ack_pc[i]        = v_buf_ack_pc[rd_add_ptr_rev[i][FQ_PTR_WIDTH-1:0]];
            assign v_ack_pld[i]       = v_buf_ack_pld[rd_add_ptr_rev[i][FQ_PTR_WIDTH-1:0]];
            assign v_fe_pld[i]        = v_buf_fe_pld[rd_add_ptr_rev[i][FQ_PTR_WIDTH-1:0]];
        end
    endgenerate


    generate
        for(genvar i=0; i < INST_READ_CHANNEL; i=i+1) begin: GEN_FQ_BUF
            toy_fetch_buffer #(
                .DEPTH  (FQ_BUF_DEPTH ),
                .MUX_IN (FQ_BUF_IN_NUM)
            //    .MUX_OUT(1            )
            ) u_fq_buffer (
                .clk      (clk             ),
                .rst_n    (rst_n           ),
                .cancel_en(cancel_en       ),
                .req_rdy  (v_buf_req_rdy[i]),
                .req_vld  (v_buf_req_vld[i]),
                .v_req_pld(v_buf_req_pld[i]),
                .v_req_en (v_buf_req_en[i] ),
                .v_ack_vld(v_buf_ack_vld[i]),
                .v_ack_rdy(v_buf_ack_rdy[i]),
                .v_ack_pc (v_buf_ack_pc[i] ),
                .v_ack_pld(v_buf_ack_pld[i]),
                .v_fe_pld (v_buf_fe_pld[i] )
            );
        end
    endgenerate




endmodule 