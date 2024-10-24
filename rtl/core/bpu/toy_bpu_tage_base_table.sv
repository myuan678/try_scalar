module toy_bpu_tage_base_table
    import toy_pack::*;
    (
        input logic                              clk,
        input logic                              rst_n,

        input  logic                             req_vld,
        input  logic                             req_wren,
        input  logic [TAGE_BASE_INDEX_WIDTH-1:0] req_addr,
        input  logic [TAGE_BASE_PRED_WIDTH-1:0]  req_wdata,
        output logic [TAGE_BASE_PRED_WIDTH-1:0]  ack_rdata,

        // to mem model
        output logic                             mem_req_vld,
        output logic                             mem_req_wren,
        output logic [TAGE_BASE_INDEX_WIDTH-1:0] mem_req_addr,
        output logic [TAGE_BASE_PRED_WIDTH-1:0]  mem_req_wdata,
        input  logic [TAGE_BASE_PRED_WIDTH-1:0]  mem_ack_rdata

    );

    assign mem_req_vld          = req_vld;
    assign mem_req_wren         = req_wren;
    assign mem_req_addr         = req_addr;
    assign mem_req_wdata        = req_wdata;
    assign ack_rdata            = mem_ack_rdata;


// toy_mem_model_tage #(
//                     .ADDR_WIDTH(TAGE_BASE_INDEX_WIDTH     ),
//                     .DATA_WIDTH(TAGE_BASE_PRED_WIDTH      )
//                    ) u_pred_sram (
//                                   .clk    (clk      ),
//                                   .en     (req_vld  ),
//                                   .addr   (req_addr ),
//                                   .rd_data(ack_rdata),
//                                   .wr_data(req_wdata),
//                                   .wr_en  (req_wren )
//                                  );

endmodule