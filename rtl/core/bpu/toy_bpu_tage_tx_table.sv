module toy_bpu_tage_tx_table
    import toy_pack::*;
    (
        input  logic                                         clk,
        input  logic                                         rst_n,

        input  logic                                         extra_rst,
        input  logic                                         req_vld,
        input  logic                                         req_wren,
        input  logic             [TAGE_TX_INDEX_WIDTH-1:0]   req_addr,
        input  tage_tx_field_pkg                             req_wdata,
        output tage_tx_field_pkg                             ack_rdata,

        // to mem model
        output logic                                         mem_req_vld,
        output logic                                         mem_req_wren,
        output logic             [TAGE_TX_INDEX_WIDTH-1:0]   mem_req_addr,
        output tage_tx_field_pkg                             mem_req_wdata,
        input  tage_tx_field_pkg                             mem_ack_rdata

    );

    localparam integer unsigned ENTRY_DATA_WIDTH = TAGE_TX_TAG_WIDTH+TAGE_TX_PRED_WIDTH+1;
    localparam integer unsigned MEM_DATA_WIDTH   = $bits(tage_tx_field_pkg);

    logic                                                 u_clear_wren;
    logic [TAGE_TX_DEPTH-1:0]                             u_clear_mask;
    logic                                                 u_flag;
    logic [TAGE_TX_USEFUL_WIDTH-1:0]                      u_mask_rdata;
    logic [TAGE_TX_INDEX_WIDTH-1:0]                       u_addr;
    logic [2**TAGE_TX_INDEX_WIDTH-1:0]                    u_addr_oh;
    logic [TAGE_TX_USEFUL_WIDTH-1:0]                      u_rdata;

    // to mem model
    assign mem_req_vld              = req_vld;
    assign mem_req_wren             = req_wren;
    assign mem_req_addr             = req_addr;
    assign mem_req_wdata            = req_wdata;
    assign ack_rdata.u_cnt          = u_mask_rdata;
    assign ack_rdata.pred_cnt       = mem_ack_rdata.pred_cnt;
    assign ack_rdata.tag            = mem_ack_rdata.tag;
    assign ack_rdata.valid          = mem_ack_rdata.valid;

    // u_clear
    assign u_rdata                  = mem_ack_rdata.u_cnt;
    assign u_clear_wren             = req_vld && req_wren;
    assign u_mask_rdata             = u_clear_mask[u_addr] ? (u_flag ? {1'b0,u_rdata[0]} : {u_rdata[1], 1'b0}) : u_rdata; // ll2
    // assign u_mask_rdata       = u_rdata; // ll2

    //==================================================
    // u_clear process
    //==================================================
    cmn_bin2onehot #(
        .BIN_WIDTH(TAGE_TX_INDEX_WIDTH)
    ) u_b2oh (
        .bin_in(u_addr),
        .onehot_out(u_addr_oh)
    );

    generate
        for(genvar i = 0; i < TAGE_TX_DEPTH; i=i+1) begin: U_CLR
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)                              u_clear_mask[i] <= 1'b0;
                else if(extra_rst)                      u_clear_mask[i] <= 1'b1;
                else if(u_clear_wren && u_addr_oh[i])   u_clear_mask[i] <= 1'b0;
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                     u_addr  <= {TAGE_TX_INDEX_WIDTH{1'b0}};
        else                                            u_addr  <= req_addr;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      u_flag  <= 1'b0;
        else if(extra_rst)                              u_flag  <= ~u_flag;
    end


// toy_mem_model_bit #(
//                     .ADDR_WIDTH(TAGE_TX_INDEX_WIDTH    ),
//                     .DATA_WIDTH(ENTRY_DATA_WIDTH       )
//                    ) u_tag_pred_sram (
//                                       .clk    (clk           ),
//                                       .en     (tag_pred_vld  ),
//                                       .addr   (tag_pred_addr ),
//                                       .rd_data(tag_pred_rdata),
//                                       .wr_data(tag_pred_wdata),
//                                       .wr_en  (tag_pred_wren )
//                                      );


// toy_mem_model_bit #(
//                     .ADDR_WIDTH(TAGE_TX_INDEX_WIDTH     ),
//                     .DATA_WIDTH(TAGE_TX_USEFUL_WIDTH    )
//                    ) u_u_sram (
//                                .clk    (clk      ),
//                                .en     (u_vld    ),
//                                .addr   (req_addr ),
//                                .rd_data(u_rdata  ),
//                                .wr_data(u_wdata  ),
//                                .wr_en  (u_wren   )
//                               );

endmodule