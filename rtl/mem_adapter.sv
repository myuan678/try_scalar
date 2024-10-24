

module toy_mem_adapter (
	input         clk                ,
	input         rst_n              ,
	input         in0_req_vld        ,
	output        in0_req_rdy        ,
	input  [31:0] in0_req_addr       ,
	input  [3:0]  in0_req_strb       ,
	input  [31:0] in0_req_data       ,
	input         in0_req_opcode     ,
	input  [3:0]  in0_req_src_id     ,
	input  [3:0]  in0_req_tgt_id     ,

	output        in0_ack_vld        ,
	input         in0_ack_rdy        ,
	output        in0_ack_opcode     ,
	output [31:0] in0_ack_data       ,
	output [3:0]  in0_ack_src_id     ,
	output [3:0]  in0_ack_tgt_id     ,
	
    output        out0_mem_en        ,
	output [31:0] out0_mem_addr      ,
	input  [31:0] out0_mem_rd_data   ,
	output [31:0] out0_mem_wr_data   ,
	output [3:0]  out0_mem_wr_byte_en,
	output        out0_mem_wr_en     );



    
    assign out0_mem_wr_byte_en  = in0_req_strb      ;
    assign out0_mem_wr_data     = in0_req_data      ;
    assign out0_mem_wr_en       = in0_req_opcode    ;





endmodule