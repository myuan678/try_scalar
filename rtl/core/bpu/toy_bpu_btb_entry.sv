module toy_bpu_btb_entry
    import toy_pack::*;
    (
        input  logic                                           clk,
        input  logic                                           rst_n,
        input  logic                                           req_vld,
        input  logic         [BTB_WAY_NUM-1:0]                 req_wren,
        input  logic         [BTB_INDEX_WIDTH-1:0]             req_addr,
        input  btb_entry_pkg                                   req_wdata,
        output btb_entry_pkg                                   ack_rdata,

        // to mem model
        output logic                                           mem_req_vld,
        output logic         [BTB_WAY_NUM-1:0]                 mem_req_wren,
        output logic         [BTB_INDEX_WIDTH-1:0]             mem_req_addr,
        output btb_entry_pkg                                   mem_req_wdata,
        input  btb_entry_pkg                                   mem_ack_rdata
    );

    localparam integer unsigned ENTRY_DATA_WIDTH = BTB_TAG_WIDTH+ADDR_WIDTH+BPU_OFFSET_WIDTH+3;

    logic [BTB_WAY_NUM-2:0]                               ack_node;
    logic [BTB_WAY_NUM-2:0]                               req_node;
    logic [ENTRY_DATA_WIDTH-1:0]                          way_ack_rdata  [BTB_WAY_NUM-1:0];
    logic [BTB_WAY_NUM-1:0]                               way_req_vld;
    logic [BTB_WAY_NUM-1:0]                               way_req_wren;

    // to mem model
    assign mem_req_vld   = req_vld;
    assign mem_req_wren  = req_wren;
    assign mem_req_addr  = req_addr;
    assign mem_req_wdata = req_wdata;
    assign ack_rdata     = mem_ack_rdata;


// // sram for btb entry
// // | valid | target | offset | cext | carry |
// generate
//     for(genvar i = 0; i < BTB_WAY_NUM; i=i+1) begin: GEN_BTB_WAY
//         toy_mem_model_bit #(
//                             .ADDR_WIDTH(BTB_INDEX_WIDTH ),
//                             .DATA_WIDTH(ENTRY_DATA_WIDTH)
//                            ) u_btb_entry_way (
//                                               .clk    (clk                   ),
//                                               .en     (way_req_vld[i]        ),
//                                               .addr   (req_addr              ),
//                                               .rd_data(way_ack_rdata[i]      ),
//                                               .wr_data(req_wdata.entry_way[i]),
//                                               .wr_en  (way_req_wren[i]       )
//                                              );
//     end
// endgenerate

// // sram for plru node
// toy_mem_model_bit #(
//                     .ADDR_WIDTH(BTB_INDEX_WIDTH),
//                     .DATA_WIDTH(BTB_WAY_NUM-1  )
//                    ) u_btb_entry_node (
//                                        .clk    (clk      ),
//                                        .en     (req_vld  ),
//                                        .addr   (req_addr ),
//                                        .rd_data(ack_node ),
//                                        .wr_data(req_node ),
//                                        .wr_en  (|req_wren)
//                                       );


endmodule 