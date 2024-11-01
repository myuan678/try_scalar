module pre_allocate
    import toy_pack::*;
    #(
      localparam  int unsigned ROB_PTR_WIDTH    = ROB_ENTRY_ID_WIDTH
     )(
       input    logic                          clk,
       input    logic                          rst_n,

       input    logic                          pcgen_req,
       output   logic   [ROB_PTR_WIDTH-1:0]    pcgen_ack_entry_id,

       input    logic                          icache_ack_vld,
       input    logic   [FETCH_DATA_WIDTH-1:0] icache_ack_pld,
       input    logic   [ROB_PTR_WIDTH-1:0]    icache_ack_entry_id,

       output   logic                          filter_vld,
       input    logic                          filter_rdy,
       output   logic   [FETCH_DATA_WIDTH-1:0] filter_pld,

       input    logic                          fe_ctrl_flush,
       output   logic                          fe_ctrl_flush_done,
       output   logic                          fe_ctrl_full
      );

    logic [ROB_PTR_WIDTH:0]       credit_cnt;
    logic                         credit_add;
    logic                         credit_sub;
    logic [ROB_PTR_WIDTH:0]       credit_cal;
    logic [FETCH_DATA_WIDTH-1:0]  rob_entry      [ROB_DEPTH-1:0];
    logic [ROB_DEPTH-1:0]         rob_entry_en;
    logic [ROB_DEPTH-1:0]         rob_entry_wait;

    logic [ROB_PTR_WIDTH:0]       rd_ptr;
    logic                         wren;
    logic                         rden;
    logic [ROB_PTR_WIDTH:0]       pre_wr_ptr;
    logic                         pre_wren;


    assign filter_vld         = rob_entry_en[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign filter_pld         = rob_entry[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign fe_ctrl_full       = credit_cnt >= ROB_DEPTH;
    assign fe_ctrl_flush_done = ~(|rob_entry_wait);
    assign pcgen_ack_entry_id = pre_wr_ptr[ROB_PTR_WIDTH-1:0];


    //===============================================
    //  credit counter
    //===============================================
    assign credit_sub         = filter_vld && filter_rdy;
    assign credit_add         = pcgen_req && (credit_cnt < ROB_DEPTH);
    assign credit_cal         = credit_add - credit_sub;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                       credit_cnt <= {(ROB_PTR_WIDTH+1){1'b0}};
        else if(fe_ctrl_flush)           credit_cnt <= {(ROB_PTR_WIDTH+1){1'b0}};           
        else if(credit_add|credit_sub)   credit_cnt <= credit_cnt + credit_cal  ;
    end


    //===============================================
    //  entry fifo && prealloc
    //===============================================
    assign wren               = icache_ack_vld;
    assign rden               = filter_vld && filter_rdy;
    assign pre_wren           = pcgen_req && (credit_cnt < ROB_DEPTH);

    // prealloc
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)             pre_wr_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush)  pre_wr_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(pre_wren)       pre_wr_ptr <= pre_wr_ptr + 1'b1;       
    end

    generate 
        for (genvar i = 0; i < ROB_DEPTH; i=i+1) begin: GEN_WAIT 
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n)                                              rob_entry_wait[i] <= 1'b0;
                else if(pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i && pre_wren)    rob_entry_wait[i] <= 1'b1;
                else if(icache_ack_entry_id==i && wren)                  rob_entry_wait[i] <= 1'b0;
            end
        end 
    endgenerate 

    // entry read enable
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                            rd_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush)                                 rd_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(rden)                                          rd_ptr <= rd_ptr + 1'b1;       
    end

    generate 
        for (genvar i = 0; i < ROB_DEPTH; i=i+1) begin: GEN_ENABLE 
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n)                                    rob_entry_en[i] <= 1'b0;
                else if(fe_ctrl_flush)                         rob_entry_en[i] <= 1'b0;
                else if(rd_ptr[ROB_PTR_WIDTH-1:0]==i && rden)  rob_entry_en[i] <= 1'b0;
                else if(icache_ack_entry_id==i && wren)        rob_entry_en[i] <= 1'b1;
            end
        end 
    endgenerate 

    // fill entry
    generate 
        for (genvar i = 0; i < ROB_DEPTH; i=i+1) begin: GEN_ENTRY 
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n)                                     rob_entry[i] <= {FETCH_DATA_WIDTH{1'b0}};
                else if(icache_ack_entry_id==i && wren)         rob_entry[i] <= icache_ack_pld;
            end 
        end 
    endgenerate 


endmodule