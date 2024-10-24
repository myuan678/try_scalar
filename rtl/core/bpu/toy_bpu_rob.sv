module toy_bpu_rob
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
        output   logic                          icache_ack_rdy,
        input    logic   [ROB_PTR_WIDTH-1:0]    icache_ack_entry_id,

        output   logic                          filter_vld,
        input    logic                          filter_rdy,
        output   logic   [FETCH_DATA_WIDTH-1:0] filter_pld,

        input    logic                          fe_ctrl_bp2_vld,
        input    logic                          fe_ctrl_bp2_flush,
        input    logic                          fe_ctrl_flush,
        output   logic                          fe_ctrl_flush_done,
        output   logic                          fe_ctrl_rdy
    );

    logic [ROB_PTR_WIDTH:0]       rd_ptr;
    logic [ROB_PTR_WIDTH:0]       eq_ptr;
    logic                         wren;
    logic                         rden;
    logic [ROB_PTR_WIDTH:0]       pre_wr_ptr;
    logic                         pre_wren;

    logic [ROB_DEPTH-1:0]         v_icache_prealloc;
    logic [ROB_DEPTH-1:0]         v_icache_ack_vld;
    logic [ROB_DEPTH-1:0]         v_fe_ctrl_bp2_vld;
    logic [ROB_DEPTH-1:0]         v_fe_ctrl_bp2_flush;
    logic [FETCH_DATA_WIDTH-1:0]  v_rob_entry_pld      [ROB_DEPTH-1:0];
    logic [ROB_DEPTH-1:0]         v_rob_entry_wait;
    logic [ROB_DEPTH-1:0]         v_rob_entry_invalid;
    logic [ROB_DEPTH-1:0]         v_rob_entry_valid;
    logic [ROB_DEPTH-1:0]         v_filter_rden;
    logic [ROB_DEPTH-1:0]         v_filter_bypass;

    logic                         current_bypass;
    logic                         next_bypass;
    logic [ROB_PTR_WIDTH:0]       next_rd_ptr;


    assign pcgen_ack_entry_id = pre_wr_ptr[ROB_PTR_WIDTH-1:0];

    assign filter_vld         = v_rob_entry_valid[rd_ptr[ROB_PTR_WIDTH-1:0]] && ~v_rob_entry_invalid[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign filter_pld         = v_rob_entry_pld[rd_ptr[ROB_PTR_WIDTH-1:0]];

    assign fe_ctrl_rdy       = ~((pre_wr_ptr == {~rd_ptr[ROB_PTR_WIDTH], rd_ptr[ROB_PTR_WIDTH-1:0]}) && v_rob_entry_wait[pre_wr_ptr[ROB_PTR_WIDTH-1:0]]);
    assign fe_ctrl_flush_done = ~(|v_rob_entry_wait);

    assign icache_ack_rdy     = 1'b1;

    //===============================================
    //  prealloc
    //===============================================
    assign wren               = icache_ack_vld;
    assign rden               = filter_vld && filter_rdy;
    assign pre_wren           = pcgen_req && fe_ctrl_rdy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       pre_wr_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush&&pcgen_req) pre_wr_ptr <= pre_wr_ptr + 1'b1;
        else if(fe_ctrl_flush)            pre_wr_ptr <= pre_wr_ptr;
        else if(pre_wren)                 pre_wr_ptr <= pre_wr_ptr + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       eq_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush&&pcgen_req) eq_ptr <= pre_wr_ptr;
        else if(fe_ctrl_flush)            eq_ptr <= pre_wr_ptr - 1'b1;
        else if(pre_wren)                 eq_ptr <= eq_ptr + 1'b1;
    end

    // entry read enable
    assign next_rd_ptr       = rd_ptr + 1'b1;
    assign current_bypass    = v_rob_entry_invalid[rd_ptr[ROB_PTR_WIDTH-1:0]]&&v_rob_entry_valid[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign next_bypass       = v_rob_entry_invalid[next_rd_ptr[ROB_PTR_WIDTH-1:0]]&&v_rob_entry_valid[next_rd_ptr[ROB_PTR_WIDTH-1:0]];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       rd_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush&&pcgen_req) rd_ptr <= pre_wr_ptr + 1'b1;
        else if(fe_ctrl_flush)            rd_ptr <= pre_wr_ptr;
        else if(current_bypass)           rd_ptr <= rd_ptr + 1'b1;
        else if(rden && next_bypass)      rd_ptr <= rd_ptr + 2'b10;
        else if(rden)                     rd_ptr <= rd_ptr + 1'b1;
    end

    //===============================================
    //  rob entry
    //===============================================
    generate
        for (genvar i = 0; i < ROB_DEPTH; i=i+1) begin: GEN_WAIT
            assign v_icache_prealloc[i]    = (pre_wr_ptr==i) && pre_wren;
            assign v_icache_ack_vld[i]     = (icache_ack_entry_id==i) && wren;
            assign v_fe_ctrl_bp2_vld[i]    = ((eq_ptr[ROB_PTR_WIDTH-1:0]==i) && fe_ctrl_bp2_vld) | ((pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i) && pcgen_req && fe_ctrl_bp2_flush);
            assign v_fe_ctrl_bp2_flush[i]  = ((eq_ptr[ROB_PTR_WIDTH-1:0]==i) && fe_ctrl_bp2_vld && fe_ctrl_bp2_flush) | ((pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i) && pcgen_req && fe_ctrl_bp2_flush);
            assign v_filter_rden[i]        = (rd_ptr[ROB_PTR_WIDTH-1:0]==i) && rden;
            assign v_filter_bypass[i]      = (((next_rd_ptr[ROB_PTR_WIDTH-1:0])==i) && v_rob_entry_valid[i] && v_rob_entry_invalid[i] && filter_rdy)
                                           | ((rd_ptr[ROB_PTR_WIDTH-1:0]==i) && v_rob_entry_valid[i] && v_rob_entry_invalid[i]);

            toy_bpu_rob_entry u_rob_entry(
                .clk              (clk                      ),
                .rst_n            (rst_n                    ),
                .icache_prealloc  (v_icache_prealloc[i]     ),
                .icache_ack_vld   (v_icache_ack_vld[i]      ),
                .icache_ack_pld   (icache_ack_pld           ),
                .fe_ctrl_bp2_vld  (v_fe_ctrl_bp2_vld[i]     ),
                .fe_ctrl_bp2_flush(v_fe_ctrl_bp2_flush[i]   ),
                .fe_ctrl_flush    (fe_ctrl_flush            ),
                .rob_entry_wait   (v_rob_entry_wait[i]      ),
                .rob_entry_vld    (v_rob_entry_valid[i]     ),
                .rob_entry_invalid(v_rob_entry_invalid[i]   ),
                .filter_rden      (v_filter_rden[i]         ),
                .filter_bypass    (v_filter_bypass[i]       ),
                .filter_pld       (v_rob_entry_pld[i]       )
            );
        end
    endgenerate





















// `ifdef TOY_SIM

//     logic vld_from_pcgen,rob_vld,rob_rdy;
//     assign vld_from_pcgen = pre_wren;
//     assign rob_vld = icache_ack_vld;
//     assign rob_rdy = icache_ack_rdy;

//     initial begin
//         forever begin
//             @(posedge clk)
//             if(pcgen_req)begin
//                 $display("ROB pre_wren enable!!!");
//                 $display("ROB pre_wren is [%h] [%h]",rst_n, pre_wr_ptr);
//             end

//             if(rob_vld&&rob_rdy)begin
//                 $display("Icache data back to rob!!!");
//                 $display("rob rdy is [%h]",icache_ack_pld);
//             end
//         end
//     end

// `endif

endmodule 