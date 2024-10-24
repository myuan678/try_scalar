//[UHDL]Content Start [md5:d827994dd9de9063cbe7b0079ec838db]
module toy_bus_DArb_node_arb_itcm_pld_type_ToyBusReq_forward_True (
	input          clk          ,
	input          rst_n        ,
	output         out0_vld     ,
	input          out0_rdy     ,
	output [31:0]  out0_addr    ,
	output [31:0]  out0_strb    ,
	output [255:0] out0_data    ,
	output         out0_opcode  ,
	output [3:0]   out0_src_id  ,
	output [3:0]   out0_tgt_id  ,
	output [9:0]   out0_sideband,
	input          in0_vld      ,
	output         in0_rdy      ,
	input  [31:0]  in0_addr     ,
	input  [31:0]  in0_strb     ,
	input  [255:0] in0_data     ,
	input          in0_opcode   ,
	input  [3:0]   in0_src_id   ,
	input  [3:0]   in0_tgt_id   ,
	input  [9:0]   in0_sideband ,
	input          in1_vld      ,
	output         in1_rdy      ,
	input  [31:0]  in1_addr     ,
	input  [31:0]  in1_strb     ,
	input  [255:0] in1_data     ,
	input          in1_opcode   ,
	input  [3:0]   in1_src_id   ,
	input  [3:0]   in1_tgt_id   ,
	input  [9:0]   in1_sideband );

	//Wire define for this module.
	wire [1:0] msg_update_en      ;
	wire [0:0] msg_update_en_bit_0;
	wire [0:0] msg_update_en_bit_1;
	wire [0:0] arb_lock_reg       ;
	wire [0:0] arb_lock           ;
	wire [0:0] bit_sel_0          ;
	wire [0:0] bit_sel_1          ;
	reg  [0:0] bit_set_reg_0      ;
	reg  [0:0] bit_set_reg_1      ;
	reg  [0:0] bit_set_locked_0   ;
	reg  [0:0] bit_set_locked_1   ;

	//Wire define for sub module.
	wire [1:0] arb_msg_update_en     ;
	wire [1:0] arb_msg_age_bits_row_0;
	wire [1:0] arb_msg_age_bits_row_1;

	//Wire define for Inout.

	//Wire sub module connect to this module and inter module connect.
	assign out0_vld = ((in0_vld & ({1{bit_set_locked_0}})) | (in1_vld & ({1{bit_set_locked_1}})));
	
	assign out0_addr = ((in0_addr & ({32{bit_set_locked_0}})) | (in1_addr & ({32{bit_set_locked_1}})));
	
	assign out0_strb = ((in0_strb & ({32{bit_set_locked_0}})) | (in1_strb & ({32{bit_set_locked_1}})));
	
	assign out0_data = ((in0_data & ({256{bit_set_locked_0}})) | (in1_data & ({256{bit_set_locked_1}})));
	
	assign out0_opcode = ((in0_opcode & ({1{bit_set_locked_0}})) | (in1_opcode & ({1{bit_set_locked_1}})));
	
	assign out0_src_id = ((in0_src_id & ({4{bit_set_locked_0}})) | (in1_src_id & ({4{bit_set_locked_1}})));
	
	assign out0_tgt_id = ((in0_tgt_id & ({4{bit_set_locked_0}})) | (in1_tgt_id & ({4{bit_set_locked_1}})));
	
	assign out0_sideband = ((in0_sideband & ({10{bit_set_locked_0}})) | (in1_sideband & ({10{bit_set_locked_1}})));
	
	assign in0_rdy = (bit_set_locked_0 && out0_rdy);
	
	assign in1_rdy = (bit_set_locked_1 && out0_rdy);
	
	assign msg_update_en = {msg_update_en_bit_0, msg_update_en_bit_1};
	
	assign msg_update_en_bit_0 = (in0_vld && in0_rdy);
	
	assign msg_update_en_bit_1 = (in1_vld && in1_rdy);
	
	assign arb_lock_reg = 1'b0;
	
	assign arb_lock = 1'b0;
	
	assign bit_sel_0 = ((~((arb_msg_age_bits_row_0[0] && in0_vld) || (arb_msg_age_bits_row_0[1] && in1_vld))) && in0_vld);
	
	assign bit_sel_1 = ((~((arb_msg_age_bits_row_1[0] && in0_vld) || (arb_msg_age_bits_row_1[1] && in1_vld))) && in1_vld);
	
	always @(posedge clk or negedge rst_n) begin
	    if(~rst_n) bit_set_reg_0 <= 1'b0;
	    else begin
	        if(arb_lock) bit_set_reg_0 <= bit_sel_0;
	    end
	end
	
	always @(posedge clk or negedge rst_n) begin
	    if(~rst_n) bit_set_reg_1 <= 1'b0;
	    else begin
	        if(arb_lock) bit_set_reg_1 <= bit_sel_1;
	    end
	end
	
	always @(*) begin
	    if(arb_lock_reg) bit_set_locked_0 = bit_set_reg_0;
	    else bit_set_locked_0 = bit_sel_0;
	end
	
	always @(*) begin
	    if(arb_lock_reg) bit_set_locked_1 = bit_set_reg_1;
	    else bit_set_locked_1 = bit_sel_1;
	end
	

	//Wire this module connect to sub module.
	assign arb_msg_update_en = msg_update_en;
	

	//module inst.
	toy_bus_CmnAgeMtx_width_2 arb_msg (
		.clk(clk),
		.rst_n(rst_n),
		.update_en(arb_msg_update_en),
		.age_bits_row_0(arb_msg_age_bits_row_0),
		.age_bits_row_1(arb_msg_age_bits_row_1));

endmodule
//[UHDL]Content End [md5:d827994dd9de9063cbe7b0079ec838db]

