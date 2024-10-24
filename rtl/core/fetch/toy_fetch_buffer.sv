module toy_fetch_buffer
    import toy_pack::*;
    #(
        parameter int unsigned DEPTH   = 32,
        parameter int unsigned MUX_IN  = 2
    //   parameter int unsigned MUX_OUT = 1
    )(
        input  logic                          clk,
        input  logic                          rst_n,

        input  logic                          cancel_en,

        output logic                          req_rdy,
        input  logic                          req_vld,
        input  fetch_queue_pkg                v_req_pld [MUX_IN-1:0],
        input  logic           [MUX_IN-1:0]   v_req_en,

        output logic                          v_ack_vld,
        input  logic                          v_ack_rdy,
        output logic         [ADDR_WIDTH-1:0] v_ack_pc  ,
        output logic         [INST_WIDTH-1:0] v_ack_pld ,
        output fe_bypass_pkg                  v_fe_pld
    );

    localparam  int unsigned CRDT_CNT_WIDTH   = $clog2(DEPTH);
    localparam  int unsigned WRITE_NUM_WIDTH  = $clog2(MUX_IN);
    localparam  int unsigned FQ_PTR_WIDTH     = $clog2(DEPTH);

    logic           [CRDT_CNT_WIDTH:0]  crdt_cnt;
    logic           [CRDT_CNT_WIDTH:0]  crdt_cal;
    logic           [CRDT_CNT_WIDTH:0]  crdt_sub;
    logic           [CRDT_CNT_WIDTH:0]  crdt_add;
    logic           [CRDT_CNT_WIDTH:0]  crdt_residue;
    logic           [WRITE_NUM_WIDTH:0] v_write_num  [MUX_IN-1:0];
    logic           [WRITE_NUM_WIDTH:0] v_read_num   ;
    fetch_queue_pkg                     queue_entry  [DEPTH-1:0];
    logic           [FQ_PTR_WIDTH:0]    wr_ptr;
    logic           [FQ_PTR_WIDTH:0]    rd_ptr;
    logic           [FQ_PTR_WIDTH:0]    wr_add_ptr   [MUX_IN-1:0];
    logic           [FQ_PTR_WIDTH:0]    rd_add_ptr   ;
    logic                               wren;
    logic                               rden;


    //===========================================================================
    // fetch buffer
    //===========================================================================
    // write num
    assign req_rdy = crdt_residue >= MUX_IN;

    generate
        for (genvar i = 0; i < MUX_IN; i=i+1) begin: GEN_WR
            if (i==0)   assign v_write_num[i] = v_req_en[i];
            else        assign v_write_num[i] = v_req_en[i] + v_write_num[i-1];
        end
    endgenerate

    // read num
    // generate
    //     for(genvar i = 0; i < MUX_OUT; i=i+1) begin: GEN_RD
    //         assign v_ack_vld[i] = (crdt_cnt>i);
    //         if(i==0)    assign v_read_num[i] = v_ack_vld[i]&&v_ack_rdy[i];
    //         else        assign v_read_num[i] = (v_ack_vld[i]&&v_ack_rdy[i]) + v_read_num[i-1];
    //     end
    // endgenerate

    // generate
    //     for (genvar i = 0; i < MUX_IN; i=i+1) begin: GEN_RD_ENTRY
    //         assign rd_add_ptr[i]        = rd_ptr + i; //TODO: pregen
    //         assign v_ack_pld[i]         = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].inst;
    //         assign v_ack_pc[i]          = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.pc;
    //         assign v_fe_pld[i].pred_pc  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.pred_pc;
    //         assign v_fe_pld[i].tgt_pc   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.tgt_pc;
    //         assign v_fe_pld[i].offset   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.offset;
    //         assign v_fe_pld[i].is_cext  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.is_cext;
    //         assign v_fe_pld[i].carry    = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.carry;
    //         assign v_fe_pld[i].inst_pld = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].inst;
    //         assign v_fe_pld[i].is_call  = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.is_call; // for test
    //         assign v_fe_pld[i].is_ret   = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.is_ret;
    //         assign v_fe_pld[i].taken    = queue_entry[rd_add_ptr[i][FQ_PTR_WIDTH-1:0]].bypass.bypass.taken;
    //     end
    // endgenerate

    assign v_ack_vld         = (crdt_cnt>0);
    assign v_read_num        = v_ack_vld&&v_ack_rdy;
    assign rd_add_ptr        = rd_ptr + 0; //TODO: pregen
    assign v_ack_pld         = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].inst;
    assign v_ack_pc          = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.pc;
    assign v_fe_pld.pred_pc  = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.pred_pc;
    assign v_fe_pld.tgt_pc   = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.tgt_pc;
    assign v_fe_pld.offset   = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.offset;
    assign v_fe_pld.is_cext  = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.is_cext;
    assign v_fe_pld.carry    = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.carry;
    assign v_fe_pld.inst_pld = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].inst;
    assign v_fe_pld.is_call  = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.is_call; // for test
    assign v_fe_pld.is_ret   = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.is_ret;
    assign v_fe_pld.is_last  = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.is_last;
    assign v_fe_pld.taken    = queue_entry[rd_add_ptr[FQ_PTR_WIDTH-1:0]].bypass.bypass.taken;

    // credit counter
    assign crdt_residue = DEPTH - crdt_cnt;
    assign crdt_add     = v_write_num[MUX_IN-1] & {(WRITE_NUM_WIDTH+1){wren}};
    assign crdt_sub     = v_read_num & {(WRITE_NUM_WIDTH+1){rden}};
    assign crdt_cal     =  crdt_add - crdt_sub;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)              crdt_cnt <= {CRDT_CNT_WIDTH{1'b0}};
        else if(cancel_en)      crdt_cnt <= {CRDT_CNT_WIDTH{1'b0}};
        else if(wren|rden)      crdt_cnt <= crdt_cnt + crdt_cal;
    end

    // pointer
    assign wren = req_rdy && req_vld;
    assign rden = |(v_ack_vld&v_ack_rdy);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          wr_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(cancel_en)  wr_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(wren)       wr_ptr <= wr_ptr + v_write_num[MUX_IN-1];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          rd_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(cancel_en)  rd_ptr <= {FQ_PTR_WIDTH{1'b0}};
        else if(rden)       rd_ptr <= rd_ptr + v_read_num;
    end

    // write queue entry
    generate
        for (genvar i = 0; i < MUX_IN; i=i+1) begin: GEN_WR_PTR
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)          wr_add_ptr[i] <= i;
                else if(cancel_en)  wr_add_ptr[i] <= i;
                else if(wren)       wr_add_ptr[i] <= wr_ptr + v_write_num[MUX_IN-1] + i;
                else                wr_add_ptr[i] <= wr_ptr + i;
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int i = 0; i < MUX_IN; i=i+1) begin
            if(wren&&v_req_en[i])  queue_entry[wr_add_ptr[i][FQ_PTR_WIDTH-1:0]] <= v_req_pld[i];
        end
    end


endmodule 