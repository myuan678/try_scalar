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

        input    logic                          bpdec_bp2_vld,
        input    logic                          bpdec_bp2_flush,

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
    logic [ROB_DEPTH-1:0]         v_bpdec_bp2_vld;
    logic [ROB_DEPTH-1:0]         v_bpdec_bp2_flush;
    logic [FETCH_DATA_WIDTH-1:0]  v_rob_entry_pld          [ROB_DEPTH-1:0];
    logic [ROB_DEPTH-1:0]         v_rob_entry_wait_0;
    logic [ROB_DEPTH-1:0]         v_rob_entry_invalid;
    logic [ROB_DEPTH-1:0]         v_rob_entry_valid;
    logic [FETCH_DATA_WIDTH-1:0]  v_rob_entry_nxt_pld      [ROB_DEPTH-1:0];
    logic [ROB_DEPTH-1:0]         v_rob_entry_nxt_invalid;
    logic [ROB_DEPTH-1:0]         v_rob_entry_nxt_valid;
    logic [ROB_DEPTH-1:0]         v_filter_rden;
    logic [ROB_DEPTH-1:0]         v_filter_bypass;

    logic                         current_bypass;
    logic                         next_bypass;
    logic [ROB_PTR_WIDTH:0]       next_rd_ptr;
    logic [ROB_PTR_WIDTH:0]       next_bypass_rd_ptr;

    logic [FETCH_DATA_WIDTH-1:0] deq_reg;
    logic                        deq_reg_wren;
    logic                        deq_valid;
    logic                        deq_valid_wren;
    logic                        deq_invalid;
    logic                        deq_invalid_wren;
    logic                        deq_bp2_vld;
    logic                        deq_icache_vld;
    logic [ROB_PTR_WIDTH-1:0]    deq_ptr_nxt; 


    assign pcgen_ack_entry_id = pre_wr_ptr[ROB_PTR_WIDTH-1:0];

    // assign filter_vld         = v_rob_entry_valid[rd_ptr[ROB_PTR_WIDTH-1:0]] && ~v_rob_entry_invalid[rd_ptr[ROB_PTR_WIDTH-1:0]];
    // assign filter_pld         = v_rob_entry_pld[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign filter_vld         = deq_valid && ~deq_invalid;
    assign filter_pld         = deq_reg;

    assign fe_ctrl_rdy        = ~((pre_wr_ptr == {~rd_ptr[ROB_PTR_WIDTH], rd_ptr[ROB_PTR_WIDTH-1:0]}) && v_rob_entry_wait_0[pre_wr_ptr[ROB_PTR_WIDTH-1:0]]);
    assign fe_ctrl_flush_done = ~(|v_rob_entry_wait_0);

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
        else if(pre_wren)                 eq_ptr <= pre_wr_ptr;
    end

    // entry read enable
    assign next_rd_ptr        = rd_ptr + 1'b1;
    assign next_bypass_rd_ptr = rd_ptr + 2'b10;
    assign current_bypass     = v_rob_entry_invalid[rd_ptr[ROB_PTR_WIDTH-1:0]]&&v_rob_entry_valid[rd_ptr[ROB_PTR_WIDTH-1:0]];
    assign next_bypass        = v_rob_entry_invalid[next_rd_ptr[ROB_PTR_WIDTH-1:0]]&&v_rob_entry_valid[next_rd_ptr[ROB_PTR_WIDTH-1:0]];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                       rd_ptr <= {ROB_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush&&pcgen_req) rd_ptr <= pre_wr_ptr + 1'b1;
        else if(fe_ctrl_flush)            rd_ptr <= pre_wr_ptr;
        else if(current_bypass)           rd_ptr <= rd_ptr + 1'b1;
        else if(rden && next_bypass)      rd_ptr <= rd_ptr + 2'b10;
        else if(rden)                     rd_ptr <= rd_ptr + 1'b1;
    end

    //===============================================
    //  Enqueue register
    //===============================================
    always_comb begin
        if(rden && next_bypass)             deq_ptr_nxt = next_bypass_rd_ptr[ROB_PTR_WIDTH-1:0];
        else if(rden | current_bypass)      deq_ptr_nxt = next_rd_ptr[ROB_PTR_WIDTH-1:0];
        else                                deq_ptr_nxt = rd_ptr[ROB_PTR_WIDTH-1:0];
    end

    // data update
    // 1. read pointer change; 2. icache ack data
    assign deq_reg_wren = rden | current_bypass | ((icache_ack_entry_id==rd_ptr[ROB_PTR_WIDTH-1:0]) && wren);

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                     deq_reg <= {(FETCH_DATA_WIDTH){1'b0}};
        else if (deq_reg_wren)          deq_reg <= v_rob_entry_nxt_pld[deq_ptr_nxt];
    end

    // invalid update
    // 1. read pointer change; 2. bp2 flush occur; 3. flush
    assign deq_invalid_wren = fe_ctrl_flush | rden | current_bypass | ((eq_ptr[ROB_PTR_WIDTH-1:0]==rd_ptr[ROB_PTR_WIDTH-1:0]) && bpdec_bp2_vld);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                      deq_invalid <= 1'b0;
        else if(deq_invalid_wren)       deq_invalid <= v_rob_entry_nxt_invalid[deq_ptr_nxt];
    end

    // valid update
    // 1. read pointer change; 2. bp2 vld; 3. icache ack; 4. flush
    assign deq_bp2_vld    = (eq_ptr[ROB_PTR_WIDTH-1:0]==rd_ptr[ROB_PTR_WIDTH-1:0]) && bpdec_bp2_vld;
    assign deq_icache_vld = (icache_ack_entry_id==rd_ptr[ROB_PTR_WIDTH-1:0]) && icache_ack_vld;
    assign deq_valid_wren = fe_ctrl_flush | rden | current_bypass | deq_bp2_vld | deq_icache_vld;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                      deq_valid <= 1'b0;
        else if(deq_valid_wren)         deq_valid <= v_rob_entry_nxt_valid[deq_ptr_nxt];
    end


    //===============================================
    //  rob entry
    //===============================================
    generate
        for (genvar i = 0; i < ROB_DEPTH; i=i+1) begin: GEN_WAIT
            assign v_icache_prealloc[i]    = (pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i) && pre_wren;
            assign v_icache_ack_vld[i]     = (icache_ack_entry_id==i) && wren;
            assign v_bpdec_bp2_vld[i]      = ((eq_ptr[ROB_PTR_WIDTH-1:0]==i) && bpdec_bp2_vld) | ((pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i) && pcgen_req && bpdec_bp2_flush);
            assign v_bpdec_bp2_flush[i]    = ((eq_ptr[ROB_PTR_WIDTH-1:0]==i) && bpdec_bp2_vld && bpdec_bp2_flush) | ((pre_wr_ptr[ROB_PTR_WIDTH-1:0]==i) && pcgen_req && bpdec_bp2_flush);
            assign v_filter_rden[i]        = (rd_ptr[ROB_PTR_WIDTH-1:0]==i) && rden;
            assign v_filter_bypass[i]      = (((next_rd_ptr[ROB_PTR_WIDTH-1:0])==i) && v_rob_entry_valid[i] && v_rob_entry_invalid[i] && filter_rdy)
            | ((rd_ptr[ROB_PTR_WIDTH-1:0]==i) && v_rob_entry_valid[i] && v_rob_entry_invalid[i]);

            toy_bpu_rob_entry u_rob_entry(
                .clk                  (clk                       ),
                .rst_n                (rst_n                     ),
                .icache_prealloc      (v_icache_prealloc[i]      ),
                .icache_ack_vld       (v_icache_ack_vld[i]       ),
                .icache_ack_pld       (icache_ack_pld            ),
                .bpdec_bp2_vld        (v_bpdec_bp2_vld[i]        ),
                .bpdec_bp2_flush      (v_bpdec_bp2_flush[i]      ),
                .fe_ctrl_flush        (fe_ctrl_flush             ),
                .rob_entry_wait_0     (v_rob_entry_wait_0[i]     ),
                .rob_entry_valid      (v_rob_entry_valid[i]      ),
                .rob_entry_invalid    (v_rob_entry_invalid[i]    ),
                .rob_entry_nxt_valid  (v_rob_entry_nxt_valid[i]  ),
                .rob_entry_nxt_invalid(v_rob_entry_nxt_invalid[i]),
                .rob_entry_nxt_pld    (v_rob_entry_nxt_pld[i]    ),
                .filter_rden          (v_filter_rden[i]          ),
                .filter_bypass        (v_filter_bypass[i]        ),
                .filter_pld           (v_rob_entry_pld[i]        )
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