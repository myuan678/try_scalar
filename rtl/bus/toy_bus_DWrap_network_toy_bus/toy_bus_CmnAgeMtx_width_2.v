//[UHDL]Content Start [md5:0601e40bd1e06ee97455d9a8a192047a]
module toy_bus_CmnAgeMtx_width_2 (
	input        clk           ,
	input        rst_n         ,
	input  [1:0] update_en     ,
	output [1:0] age_bits_row_0,
	output [1:0] age_bits_row_1);

	//Wire define for this module.
	wire [0:0] age_bit_0_0;
	reg  [0:0] age_bit_0_1;
	wire [0:0] age_bit_1_1;
	wire [0:0] age_bit_1_0;

	//Wire define for sub module.

	//Wire define for Inout.

	//Wire sub module connect to this module and inter module connect.
	assign age_bits_row_0 = {age_bit_0_1, age_bit_0_0};
	
	assign age_bits_row_1 = {age_bit_1_1, age_bit_1_0};
	
	assign age_bit_0_0 = 1'b0;
	
	always @(posedge clk or negedge rst_n) begin
	    if(~rst_n) age_bit_0_1 <= 1'b0;
	    else age_bit_0_1 <= update_en[1];
	end
	
	assign age_bit_1_1 = 1'b0;
	
	assign age_bit_1_0 = (!age_bit_0_1);
	

	//Wire this module connect to sub module.

	//module inst.

endmodule
//[UHDL]Content End [md5:0601e40bd1e06ee97455d9a8a192047a]

