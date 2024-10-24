

module toy_mem_top 
    import toy_pack::*;
(

    input  logic                           clk                      ,
    input  logic                           rst_n                    ,

    input  logic [ADDR_WIDTH-1:0]          inst_mem_addr            ,
    output logic [BUS_DATA_WIDTH-1:0]      inst_mem_rd_data         ,
    input  logic [BUS_DATA_WIDTH-1:0]      inst_mem_wr_data         ,
    input  logic [BUS_DATA_WIDTH/8-1:0]    inst_mem_wr_byte_en      ,
    input  logic                           inst_mem_wr_en           ,
    input  logic                           inst_mem_en              ,
    input  logic [FETCH_SB_WIDTH-1:0]      inst_mem_req_sideband    ,
    output logic [FETCH_SB_WIDTH-1:0]      inst_mem_ack_sideband    ,

    input  logic [ADDR_WIDTH-1:0]          dtcm_mem_addr            ,
    output logic [BUS_DATA_WIDTH-1:0]      dtcm_mem_rd_data         ,
    input  logic [BUS_DATA_WIDTH-1:0]      dtcm_mem_wr_data         ,
    input  logic [BUS_DATA_WIDTH/8-1:0]    dtcm_mem_wr_byte_en      ,
    input  logic                           dtcm_mem_wr_en           ,
    input  logic                           dtcm_mem_en              ,
    input  logic [FETCH_SB_WIDTH-1:0]      dtcm_mem_req_sideband    ,
    output logic [FETCH_SB_WIDTH-1:0]      dtcm_mem_ack_sideband    

);



//============================================================
// Memory
//============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            inst_mem_ack_sideband <= 0;
        end
        else if(inst_mem_en && ~inst_mem_wr_en)begin
            inst_mem_ack_sideband <= inst_mem_req_sideband;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            dtcm_mem_ack_sideband <= 0;
        end
        else if(dtcm_mem_en && ~dtcm_mem_wr_en)begin
            dtcm_mem_ack_sideband <= dtcm_mem_req_sideband;
        end
    end
 
    // replace
    toy_mem_model #(
        .ARGPARSE_KEY   ("HEX"                  ),
        .ADDR_WIDTH     (ADDR_WIDTH             ),
        .DATA_WIDTH     (BUS_DATA_WIDTH         ),
        .FETCH_SB_WIDTH (FETCH_SB_WIDTH         ))
    u_inst_mem (
        .clk            (clk                    ),
        .en             (inst_mem_en            ),
        .addr           (inst_mem_addr          ),
        .rd_data        (inst_mem_rd_data       ),
        .wr_data        (inst_mem_wr_data       ),
        .wr_byte_en     (inst_mem_wr_byte_en    ),
        .wr_en          (inst_mem_wr_en         ),
        .req_send_back  (10'd0  ),
        .ack_send_back  (     ));

    toy_mem_model #(
        .ARGPARSE_KEY   ("DATA_HEX"             ),
        .ADDR_WIDTH     (ADDR_WIDTH             ),
        .DATA_WIDTH     (BUS_DATA_WIDTH         ),
        .FETCH_SB_WIDTH (FETCH_SB_WIDTH         ))
    u_data_mem (
        .clk            (clk                    ),
        .en             (dtcm_mem_en            ),
        .addr           (dtcm_mem_addr          ),
        .rd_data        (dtcm_mem_rd_data       ),
        .wr_data        (dtcm_mem_wr_data       ),
        .wr_byte_en     (dtcm_mem_wr_byte_en    ),
        .wr_en          (dtcm_mem_wr_en         ),
        .req_send_back  (10'd0  ),
        .ack_send_back  (     ));



endmodule