//[UHDL]Content Start [md5:ebba85af4ee672b670e857244a3d8266]
module toy_bus_DDec_node_dec_lsu_pld_type_ToyBusReq_forward_True (
	input          in0_vld      ,
	output         in0_rdy      ,
	input  [31:0]  in0_addr     ,
	input  [31:0]  in0_strb     ,
	input  [255:0] in0_data     ,
	input          in0_opcode   ,
	input  [3:0]   in0_src_id   ,
	input  [3:0]   in0_tgt_id   ,
	input  [9:0]   in0_sideband ,
	output         out0_vld     ,
	input          out0_rdy     ,
	output [31:0]  out0_addr    ,
	output [31:0]  out0_strb    ,
	output [255:0] out0_data    ,
	output         out0_opcode  ,
	output [3:0]   out0_src_id  ,
	output [3:0]   out0_tgt_id  ,
	output [9:0]   out0_sideband,
	output         out1_vld     ,
	input          out1_rdy     ,
	output [31:0]  out1_addr    ,
	output [31:0]  out1_strb    ,
	output [255:0] out1_data    ,
	output         out1_opcode  ,
	output [3:0]   out1_src_id  ,
	output [3:0]   out1_tgt_id  ,
	output [9:0]   out1_sideband);

	//Wire define for this module.
	wire [0:0] hit_tgtid_2__to_rteid_0;
	wire [0:0] hit_tgtid_3__to_rteid_1;
	wire [0:0] hit_tgtid_4__to_rteid_1;
	wire [0:0] channel_mask_0         ;
	wire [0:0] masked_rdy_0           ;
	wire [0:0] channel_mask_1         ;
	wire [0:0] masked_rdy_1           ;

	//Wire define for sub module.

	//Wire define for Inout.

	//Wire sub module connect to this module and inter module connect.
	assign in0_rdy = (masked_rdy_0 || masked_rdy_1);
	
	assign out0_vld = (in0_vld && channel_mask_0);
	
	assign out0_addr = in0_addr;
	
	assign out0_strb = in0_strb;
	
	assign out0_data = in0_data;
	
	assign out0_opcode = in0_opcode;
	
	assign out0_src_id = in0_src_id;
	
	assign out0_tgt_id = in0_tgt_id;
	
	assign out0_sideband = in0_sideband;
	
	assign out1_vld = (in0_vld && channel_mask_1);
	
	assign out1_addr = in0_addr;
	
	assign out1_strb = in0_strb;
	
	assign out1_data = in0_data;
	
	assign out1_opcode = in0_opcode;
	
	assign out1_src_id = in0_src_id;
	
	assign out1_tgt_id = in0_tgt_id;
	
	assign out1_sideband = in0_sideband;
	
	assign hit_tgtid_2__to_rteid_0 = (in0_tgt_id == 4'b10);
	
	assign hit_tgtid_3__to_rteid_1 = (in0_tgt_id == 4'b11);
	
	assign hit_tgtid_4__to_rteid_1 = (in0_tgt_id == 4'b100);
	
	assign channel_mask_0 = (hit_tgtid_2__to_rteid_0);
	
	assign masked_rdy_0 = (out0_rdy && channel_mask_0);
	
	assign channel_mask_1 = (hit_tgtid_3__to_rteid_1 || hit_tgtid_4__to_rteid_1);
	
	assign masked_rdy_1 = (out1_rdy && channel_mask_1);
	

	//Wire this module connect to sub module.

	//module inst.

endmodule
//[UHDL]Content End [md5:ebba85af4ee672b670e857244a3d8266]

