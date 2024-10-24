module toy_bpu_mem
    import toy_pack::*;
    (
        input                                              clk,
        input                                              rst_n,

        input  logic                                       tb_mem_req_wren,
        input  logic                                       tb_mem_req_vld,
        input  logic [TAGE_BASE_INDEX_WIDTH-1:0]           tb_mem_req_addr,
        input  logic [TAGE_BASE_PRED_WIDTH-1:0]            tb_mem_req_wdata,
        output logic [TAGE_BASE_PRED_WIDTH-1:0]            tb_mem_ack_rdata,

        input  logic             [TAGE_TABLE_NUM-1:0]      tx_mem_req_vld,
        input  logic             [TAGE_TABLE_NUM-1:0]      tx_mem_req_wren,
        input  logic             [TAGE_TX_INDEX_WIDTH-1:0] tx_mem_req_addr  [TAGE_TABLE_NUM-1:0],
        input  tage_tx_field_pkg                           tx_mem_req_wdata [TAGE_TABLE_NUM-1:0],
        output tage_tx_field_pkg                           tx_mem_ack_rdata [TAGE_TABLE_NUM-1:0],

        input  logic                                       btb_mem_req_vld,
        input  logic         [BTB_WAY_NUM-1:0]             btb_mem_req_wren,
        input  logic         [BTB_INDEX_WIDTH-1:0]         btb_mem_req_addr,
        input  btb_entry_pkg                               btb_mem_req_wdata,
        output btb_entry_pkg                               btb_mem_ack_rdata

    );
    localparam TX_DATA_WIDTH        = $bits(tage_tx_field_pkg);
    localparam BTB_ENTRY_DATA_WIDTH = BTB_TAG_WIDTH+ADDR_WIDTH+BPU_OFFSET_WIDTH+3;

    logic [BTB_WAY_NUM-2:0]            ack_node;
    logic [BTB_ENTRY_DATA_WIDTH-1:0]   way_ack_rdata  [BTB_WAY_NUM-1:0];

    toy_mem_model_tage #(
        .ADDR_WIDTH(TAGE_BASE_INDEX_WIDTH     ),
        .DATA_WIDTH(TAGE_BASE_PRED_WIDTH      )
    ) u_pred_sram (
        .clk    (clk             ),
        .en     (tb_mem_req_vld  ),
        .addr   (tb_mem_req_addr ),
        .rd_data(tb_mem_ack_rdata),
        .wr_data(tb_mem_req_wdata),
        .wr_en  (tb_mem_req_wren )
    );

    generate
        for(genvar i=0; i < TAGE_TABLE_NUM; i=i+1) begin: GEN_TABLE
            toy_mem_model_bit #(
                .ADDR_WIDTH(TAGE_TX_INDEX_WIDTH),
                .DATA_WIDTH(TX_DATA_WIDTH      )
            ) u_tag_pred_sram (
                .clk    (clk                ),
                .en     (tx_mem_req_vld[i]  ),
                .addr   (tx_mem_req_addr[i] ),
                .rd_data(tx_mem_ack_rdata[i]),
                .wr_data(tx_mem_req_wdata[i]),
                .wr_en  (tx_mem_req_wren[i] )
            );
        end
    endgenerate


    // sram for btb entry
    // | valid | target | offset | cext | carry |

    generate
        for (genvar i = 0; i < BTB_WAY_NUM; i=i+1) begin: GEN_WAY_ACK
            assign btb_mem_ack_rdata.entry_way[i]   = way_ack_rdata[i];
        end
    endgenerate

    assign btb_mem_ack_rdata.node = ack_node;

    generate
        for(genvar i = 0; i < BTB_WAY_NUM; i=i+1) begin: GEN_BTB_WAY
            toy_mem_model_bit #(
                .ADDR_WIDTH(BTB_INDEX_WIDTH     ),
                .DATA_WIDTH(BTB_ENTRY_DATA_WIDTH)
            ) u_btb_entry_way (
                .clk    (clk                           ),
                .en     (btb_mem_req_vld               ),
                .addr   (btb_mem_req_addr              ),
                .rd_data(way_ack_rdata[i]              ),
                .wr_data(btb_mem_req_wdata.entry_way[i]),
                .wr_en  (btb_mem_req_wren[i]           )
            );
        end
    endgenerate

    // sram for plru node
    toy_mem_model_bit #(
        .ADDR_WIDTH(BTB_INDEX_WIDTH),
        .DATA_WIDTH(BTB_WAY_NUM-1  )
    ) u_btb_entry_node (
        .clk    (clk                   ),
        .en     (btb_mem_req_vld       ),
        .addr   (btb_mem_req_addr      ),
        .rd_data(ack_node              ),
        .wr_data(btb_mem_req_wdata.node),
        .wr_en  (|btb_mem_req_wren     )
    );

endmodule 