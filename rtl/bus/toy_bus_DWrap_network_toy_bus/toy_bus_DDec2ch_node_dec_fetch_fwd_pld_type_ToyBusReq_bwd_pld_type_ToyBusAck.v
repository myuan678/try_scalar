//[UHDL]Content Start [md5:66d02dc8894cb7099d1159a259047b2f]
module toy_bus_DDec2ch_node_dec_fetch_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck (
	input          clk              ,
	input          rst_n            ,
	input          in0_req_vld      ,
	output         in0_req_rdy      ,
	input  [31:0]  in0_req_addr     ,
	input  [31:0]  in0_req_strb     ,
	input  [255:0] in0_req_data     ,
	input          in0_req_opcode   ,
	input  [3:0]   in0_req_src_id   ,
	input  [3:0]   in0_req_tgt_id   ,
	input  [9:0]   in0_req_sideband ,
	output         in0_ack_vld      ,
	input          in0_ack_rdy      ,
	output         in0_ack_opcode   ,
	output [255:0] in0_ack_data     ,
	output [9:0]   in0_ack_sideband ,
	output [3:0]   in0_ack_src_id   ,
	output [3:0]   in0_ack_tgt_id   ,
	output         out0_req_vld     ,
	input          out0_req_rdy     ,
	output [31:0]  out0_req_addr    ,
	output [31:0]  out0_req_strb    ,
	output [255:0] out0_req_data    ,
	output         out0_req_opcode  ,
	output [3:0]   out0_req_src_id  ,
	output [3:0]   out0_req_tgt_id  ,
	output [9:0]   out0_req_sideband,
	output         out1_req_vld     ,
	input          out1_req_rdy     ,
	output [31:0]  out1_req_addr    ,
	output [31:0]  out1_req_strb    ,
	output [255:0] out1_req_data    ,
	output         out1_req_opcode  ,
	output [3:0]   out1_req_src_id  ,
	output [3:0]   out1_req_tgt_id  ,
	output [9:0]   out1_req_sideband,
	input          out0_ack_vld     ,
	output         out0_ack_rdy     ,
	input          out0_ack_opcode  ,
	input  [255:0] out0_ack_data    ,
	input  [9:0]   out0_ack_sideband,
	input  [3:0]   out0_ack_src_id  ,
	input  [3:0]   out0_ack_tgt_id  ,
	input          out1_ack_vld     ,
	output         out1_ack_rdy     ,
	input          out1_ack_opcode  ,
	input  [255:0] out1_ack_data    ,
	input  [9:0]   out1_ack_sideband,
	input  [3:0]   out1_ack_src_id  ,
	input  [3:0]   out1_ack_tgt_id  );

	//Wire define for this module.

	//Wire define for sub module.
	wire  u_arb_in0_rdy;
	wire  u_arb_in1_rdy;

	//Wire define for Inout.

	//Wire sub module connect to this module and inter module connect.
	assign out0_ack_rdy = u_arb_in0_rdy;
	
	assign out1_ack_rdy = u_arb_in1_rdy;
	

	//Wire this module connect to sub module.

	//module inst.
	toy_bus_DDec_node_dec_fetch_pld_type_ToyBusReq_forward_True u_dec (
		.in0_vld(in0_req_vld),
		.in0_rdy(in0_req_rdy),
		.in0_addr(in0_req_addr),
		.in0_strb(in0_req_strb),
		.in0_data(in0_req_data),
		.in0_opcode(in0_req_opcode),
		.in0_src_id(in0_req_src_id),
		.in0_tgt_id(in0_req_tgt_id),
		.in0_sideband(in0_req_sideband),
		.out0_vld(out0_req_vld),
		.out0_rdy(out0_req_rdy),
		.out0_addr(out0_req_addr),
		.out0_strb(out0_req_strb),
		.out0_data(out0_req_data),
		.out0_opcode(out0_req_opcode),
		.out0_src_id(out0_req_src_id),
		.out0_tgt_id(out0_req_tgt_id),
		.out0_sideband(out0_req_sideband),
		.out1_vld(out1_req_vld),
		.out1_rdy(out1_req_rdy),
		.out1_addr(out1_req_addr),
		.out1_strb(out1_req_strb),
		.out1_data(out1_req_data),
		.out1_opcode(out1_req_opcode),
		.out1_src_id(out1_req_src_id),
		.out1_tgt_id(out1_req_tgt_id),
		.out1_sideband(out1_req_sideband));
	toy_bus_DArb_node_dec_fetch_pld_type_ToyBusAck_forward_False u_arb (
		.clk(clk),
		.rst_n(rst_n),
		.out0_vld(in0_ack_vld),
		.out0_rdy(in0_ack_rdy),
		.out0_opcode(in0_ack_opcode),
		.out0_data(in0_ack_data),
		.out0_sideband(in0_ack_sideband),
		.out0_src_id(in0_ack_src_id),
		.out0_tgt_id(in0_ack_tgt_id),
		.in0_vld(out0_ack_vld),
		.in0_rdy(u_arb_in0_rdy),
		.in0_opcode(out0_ack_opcode),
		.in0_data(out0_ack_data),
		.in0_sideband(out0_ack_sideband),
		.in0_src_id(out0_ack_src_id),
		.in0_tgt_id(out0_ack_tgt_id),
		.in1_vld(out1_ack_vld),
		.in1_rdy(u_arb_in1_rdy),
		.in1_opcode(out1_ack_opcode),
		.in1_data(out1_ack_data),
		.in1_sideband(out1_ack_sideband),
		.in1_src_id(out1_ack_src_id),
		.in1_tgt_id(out1_ack_tgt_id));

endmodule
//[UHDL]Content End [md5:66d02dc8894cb7099d1159a259047b2f]

