//[UHDL]Content Start [md5:2111b132991b4982eb07c16fec96a000]
module toy_bus_DWrap_network_toy_bus (
	input          clk                       ,
	input          rst_n                     ,
	input          fetch_in0_req_vld         ,
	output         fetch_in0_req_rdy         ,
	input  [31:0]  fetch_in0_req_addr        ,
	input  [255:0] fetch_in0_req_data        ,
	input  [31:0]  fetch_in0_req_strb        ,
	input          fetch_in0_req_opcode      ,
	input  [9:0]   fetch_in0_req_sideband    ,
	output         fetch_in0_ack_vld         ,
	input          fetch_in0_ack_rdy         ,
	output [255:0] fetch_in0_ack_data        ,
	output [9:0]   fetch_in0_ack_sideband    ,
	input          lsu_in0_req_vld           ,
	output         lsu_in0_req_rdy           ,
	input  [31:0]  lsu_in0_req_addr          ,
	input  [255:0] lsu_in0_req_data          ,
	input  [31:0]  lsu_in0_req_strb          ,
	input          lsu_in0_req_opcode        ,
	input  [9:0]   lsu_in0_req_sideband      ,
	output         lsu_in0_ack_vld           ,
	input          lsu_in0_ack_rdy           ,
	output [255:0] lsu_in0_ack_data          ,
	output [9:0]   lsu_in0_ack_sideband      ,
	output         itcm_out0_mem_en          ,
	output [31:0]  itcm_out0_mem_addr        ,
	input  [255:0] itcm_out0_mem_rd_data     ,
	output [255:0] itcm_out0_mem_wr_data     ,
	output [31:0]  itcm_out0_mem_wr_byte_en  ,
	output         itcm_out0_mem_wr_en       ,
	output [9:0]   itcm_out0_mem_req_sideband,
	input  [9:0]   itcm_out0_mem_ack_sideband,
	output         dtcm_out0_mem_en          ,
	output [31:0]  dtcm_out0_mem_addr        ,
	input  [255:0] dtcm_out0_mem_rd_data     ,
	output [255:0] dtcm_out0_mem_wr_data     ,
	output [31:0]  dtcm_out0_mem_wr_byte_en  ,
	output         dtcm_out0_mem_wr_en       ,
	output [9:0]   dtcm_out0_mem_req_sideband,
	input  [9:0]   dtcm_out0_mem_ack_sideband,
	output         eslv_out0_mem_en          ,
	output [31:0]  eslv_out0_mem_addr        ,
	input  [255:0] eslv_out0_mem_rd_data     ,
	output [255:0] eslv_out0_mem_wr_data     ,
	output [31:0]  eslv_out0_mem_wr_byte_en  ,
	output         eslv_out0_mem_wr_en       ,
	output [9:0]   eslv_out0_mem_req_sideband,
	input  [9:0]   eslv_out0_mem_ack_sideband);

	//Wire define for this module.

	//Wire define for sub module.
	wire         dec_fetch_TO_fetch_SIG_in0_req_rdy         ;
	wire         dec_fetch_TO_fetch_SIG_in0_ack_vld         ;
	wire         dec_fetch_TO_fetch_SIG_in0_ack_opcode      ;
	wire [255:0] dec_fetch_TO_fetch_SIG_in0_ack_data        ;
	wire [9:0]   dec_fetch_TO_fetch_SIG_in0_ack_sideband    ;
	wire [3:0]   dec_fetch_TO_fetch_SIG_in0_ack_src_id      ;
	wire [3:0]   dec_fetch_TO_fetch_SIG_in0_ack_tgt_id      ;
	wire         dec_lsu_TO_lsu_SIG_in0_req_rdy             ;
	wire         dec_lsu_TO_lsu_SIG_in0_ack_vld             ;
	wire         dec_lsu_TO_lsu_SIG_in0_ack_opcode          ;
	wire [255:0] dec_lsu_TO_lsu_SIG_in0_ack_data            ;
	wire [9:0]   dec_lsu_TO_lsu_SIG_in0_ack_sideband        ;
	wire [3:0]   dec_lsu_TO_lsu_SIG_in0_ack_src_id          ;
	wire [3:0]   dec_lsu_TO_lsu_SIG_in0_ack_tgt_id          ;
	wire         itcm_in0_req_vld                           ;
	wire [31:0]  arb_itcm_TO_itcm_SIG_out0_req_addr         ;
	wire [31:0]  arb_itcm_TO_itcm_SIG_out0_req_strb         ;
	wire [255:0] arb_itcm_TO_itcm_SIG_out0_req_data         ;
	wire         itcm_in0_req_opcode                        ;
	wire [3:0]   arb_itcm_TO_itcm_SIG_out0_req_src_id       ;
	wire [3:0]   arb_itcm_TO_itcm_SIG_out0_req_tgt_id       ;
	wire [9:0]   arb_itcm_TO_itcm_SIG_out0_req_sideband     ;
	wire         arb_itcm_TO_itcm_SIG_out0_ack_rdy          ;
	wire         dtcm_in0_req_vld                           ;
	wire [31:0]  dec_dmem_TO_dtcm_SIG_out0_req_addr         ;
	wire [31:0]  dec_dmem_TO_dtcm_SIG_out0_req_strb         ;
	wire [255:0] dec_dmem_TO_dtcm_SIG_out0_req_data         ;
	wire         dtcm_in0_req_opcode                        ;
	wire [3:0]   dec_dmem_TO_dtcm_SIG_out0_req_src_id       ;
	wire [3:0]   dec_dmem_TO_dtcm_SIG_out0_req_tgt_id       ;
	wire [9:0]   dec_dmem_TO_dtcm_SIG_out0_req_sideband     ;
	wire         dec_dmem_TO_dtcm_SIG_out0_ack_rdy          ;
	wire         eslv_in0_req_vld                           ;
	wire [31:0]  dec_dmem_TO_eslv_SIG_out1_req_addr         ;
	wire [31:0]  dec_dmem_TO_eslv_SIG_out1_req_strb         ;
	wire [255:0] dec_dmem_TO_eslv_SIG_out1_req_data         ;
	wire         eslv_in0_req_opcode                        ;
	wire [3:0]   dec_dmem_TO_eslv_SIG_out1_req_src_id       ;
	wire [3:0]   dec_dmem_TO_eslv_SIG_out1_req_tgt_id       ;
	wire [9:0]   dec_dmem_TO_eslv_SIG_out1_req_sideband     ;
	wire         dec_dmem_TO_eslv_SIG_out1_ack_rdy          ;
	wire         fetch_TO_dec_fetch_SIG_out0_req_vld        ;
	wire [31:0]  fetch_TO_dec_fetch_SIG_out0_req_addr       ;
	wire [31:0]  fetch_TO_dec_fetch_SIG_out0_req_strb       ;
	wire [255:0] fetch_TO_dec_fetch_SIG_out0_req_data       ;
	wire         fetch_TO_dec_fetch_SIG_out0_req_opcode     ;
	wire [3:0]   fetch_TO_dec_fetch_SIG_out0_req_src_id     ;
	wire [3:0]   fetch_TO_dec_fetch_SIG_out0_req_tgt_id     ;
	wire [9:0]   fetch_TO_dec_fetch_SIG_out0_req_sideband   ;
	wire         fetch_TO_dec_fetch_SIG_out0_ack_rdy        ;
	wire         arb_itcm_TO_dec_fetch_SIG_in0_req_rdy      ;
	wire         arb_dtcm_TO_dec_fetch_SIG_in0_req_rdy      ;
	wire         arb_itcm_TO_dec_fetch_SIG_in0_ack_vld      ;
	wire         arb_itcm_TO_dec_fetch_SIG_in0_ack_opcode   ;
	wire [255:0] arb_itcm_TO_dec_fetch_SIG_in0_ack_data     ;
	wire [9:0]   arb_itcm_TO_dec_fetch_SIG_in0_ack_sideband ;
	wire [3:0]   arb_itcm_TO_dec_fetch_SIG_in0_ack_src_id   ;
	wire [3:0]   arb_itcm_TO_dec_fetch_SIG_in0_ack_tgt_id   ;
	wire         arb_dtcm_TO_dec_fetch_SIG_in0_ack_vld      ;
	wire         arb_dtcm_TO_dec_fetch_SIG_in0_ack_opcode   ;
	wire [255:0] arb_dtcm_TO_dec_fetch_SIG_in0_ack_data     ;
	wire [9:0]   arb_dtcm_TO_dec_fetch_SIG_in0_ack_sideband ;
	wire [3:0]   arb_dtcm_TO_dec_fetch_SIG_in0_ack_src_id   ;
	wire [3:0]   arb_dtcm_TO_dec_fetch_SIG_in0_ack_tgt_id   ;
	wire         lsu_TO_dec_lsu_SIG_out0_req_vld            ;
	wire [31:0]  lsu_TO_dec_lsu_SIG_out0_req_addr           ;
	wire [31:0]  lsu_TO_dec_lsu_SIG_out0_req_strb           ;
	wire [255:0] lsu_TO_dec_lsu_SIG_out0_req_data           ;
	wire         lsu_TO_dec_lsu_SIG_out0_req_opcode         ;
	wire [3:0]   lsu_TO_dec_lsu_SIG_out0_req_src_id         ;
	wire [3:0]   lsu_TO_dec_lsu_SIG_out0_req_tgt_id         ;
	wire [9:0]   lsu_TO_dec_lsu_SIG_out0_req_sideband       ;
	wire         lsu_TO_dec_lsu_SIG_out0_ack_rdy            ;
	wire         arb_itcm_TO_dec_lsu_SIG_in1_req_rdy        ;
	wire         arb_dtcm_TO_dec_lsu_SIG_in1_req_rdy        ;
	wire         arb_itcm_TO_dec_lsu_SIG_in1_ack_vld        ;
	wire         arb_itcm_TO_dec_lsu_SIG_in1_ack_opcode     ;
	wire [255:0] arb_itcm_TO_dec_lsu_SIG_in1_ack_data       ;
	wire [9:0]   arb_itcm_TO_dec_lsu_SIG_in1_ack_sideband   ;
	wire [3:0]   arb_itcm_TO_dec_lsu_SIG_in1_ack_src_id     ;
	wire [3:0]   arb_itcm_TO_dec_lsu_SIG_in1_ack_tgt_id     ;
	wire         arb_dtcm_TO_dec_lsu_SIG_in1_ack_vld        ;
	wire         arb_dtcm_TO_dec_lsu_SIG_in1_ack_opcode     ;
	wire [255:0] arb_dtcm_TO_dec_lsu_SIG_in1_ack_data       ;
	wire [9:0]   arb_dtcm_TO_dec_lsu_SIG_in1_ack_sideband   ;
	wire [3:0]   arb_dtcm_TO_dec_lsu_SIG_in1_ack_src_id     ;
	wire [3:0]   arb_dtcm_TO_dec_lsu_SIG_in1_ack_tgt_id     ;
	wire         arb_dtcm_TO_dec_dmem_SIG_out0_req_vld      ;
	wire [31:0]  arb_dtcm_TO_dec_dmem_SIG_out0_req_addr     ;
	wire [31:0]  arb_dtcm_TO_dec_dmem_SIG_out0_req_strb     ;
	wire [255:0] arb_dtcm_TO_dec_dmem_SIG_out0_req_data     ;
	wire         arb_dtcm_TO_dec_dmem_SIG_out0_req_opcode   ;
	wire [3:0]   arb_dtcm_TO_dec_dmem_SIG_out0_req_src_id   ;
	wire [3:0]   arb_dtcm_TO_dec_dmem_SIG_out0_req_tgt_id   ;
	wire [9:0]   arb_dtcm_TO_dec_dmem_SIG_out0_req_sideband ;
	wire         arb_dtcm_TO_dec_dmem_SIG_out0_ack_rdy      ;
	wire         dtcm_TO_dec_dmem_SIG_in0_req_rdy           ;
	wire         eslv_TO_dec_dmem_SIG_in0_req_rdy           ;
	wire         dtcm_TO_dec_dmem_SIG_in0_ack_vld           ;
	wire         dtcm_TO_dec_dmem_SIG_in0_ack_opcode        ;
	wire [255:0] dtcm_TO_dec_dmem_SIG_in0_ack_data          ;
	wire [9:0]   dtcm_TO_dec_dmem_SIG_in0_ack_sideband      ;
	wire [3:0]   dtcm_TO_dec_dmem_SIG_in0_ack_src_id        ;
	wire [3:0]   dtcm_TO_dec_dmem_SIG_in0_ack_tgt_id        ;
	wire         eslv_TO_dec_dmem_SIG_in0_ack_vld           ;
	wire         eslv_TO_dec_dmem_SIG_in0_ack_opcode        ;
	wire [255:0] eslv_TO_dec_dmem_SIG_in0_ack_data          ;
	wire [9:0]   eslv_TO_dec_dmem_SIG_in0_ack_sideband      ;
	wire [3:0]   eslv_TO_dec_dmem_SIG_in0_ack_src_id        ;
	wire [3:0]   eslv_TO_dec_dmem_SIG_in0_ack_tgt_id        ;
	wire         dec_dmem_TO_arb_dtcm_SIG_in0_req_rdy       ;
	wire         dec_dmem_TO_arb_dtcm_SIG_in0_ack_vld       ;
	wire         dec_dmem_TO_arb_dtcm_SIG_in0_ack_opcode    ;
	wire [255:0] dec_dmem_TO_arb_dtcm_SIG_in0_ack_data      ;
	wire [9:0]   dec_dmem_TO_arb_dtcm_SIG_in0_ack_sideband  ;
	wire [3:0]   dec_dmem_TO_arb_dtcm_SIG_in0_ack_src_id    ;
	wire [3:0]   dec_dmem_TO_arb_dtcm_SIG_in0_ack_tgt_id    ;
	wire         dec_fetch_TO_arb_dtcm_SIG_out1_req_vld     ;
	wire [31:0]  dec_fetch_TO_arb_dtcm_SIG_out1_req_addr    ;
	wire [31:0]  dec_fetch_TO_arb_dtcm_SIG_out1_req_strb    ;
	wire [255:0] dec_fetch_TO_arb_dtcm_SIG_out1_req_data    ;
	wire         dec_fetch_TO_arb_dtcm_SIG_out1_req_opcode  ;
	wire [3:0]   dec_fetch_TO_arb_dtcm_SIG_out1_req_src_id  ;
	wire [3:0]   dec_fetch_TO_arb_dtcm_SIG_out1_req_tgt_id  ;
	wire [9:0]   dec_fetch_TO_arb_dtcm_SIG_out1_req_sideband;
	wire         dec_lsu_TO_arb_dtcm_SIG_out1_req_vld       ;
	wire [31:0]  dec_lsu_TO_arb_dtcm_SIG_out1_req_addr      ;
	wire [31:0]  dec_lsu_TO_arb_dtcm_SIG_out1_req_strb      ;
	wire [255:0] dec_lsu_TO_arb_dtcm_SIG_out1_req_data      ;
	wire         dec_lsu_TO_arb_dtcm_SIG_out1_req_opcode    ;
	wire [3:0]   dec_lsu_TO_arb_dtcm_SIG_out1_req_src_id    ;
	wire [3:0]   dec_lsu_TO_arb_dtcm_SIG_out1_req_tgt_id    ;
	wire [9:0]   dec_lsu_TO_arb_dtcm_SIG_out1_req_sideband  ;
	wire         dec_fetch_TO_arb_dtcm_SIG_out1_ack_rdy     ;
	wire         dec_lsu_TO_arb_dtcm_SIG_out1_ack_rdy       ;
	wire         itcm_TO_arb_itcm_SIG_in0_req_rdy           ;
	wire         itcm_TO_arb_itcm_SIG_in0_ack_vld           ;
	wire         itcm_TO_arb_itcm_SIG_in0_ack_opcode        ;
	wire [255:0] itcm_TO_arb_itcm_SIG_in0_ack_data          ;
	wire [9:0]   itcm_TO_arb_itcm_SIG_in0_ack_sideband      ;
	wire [3:0]   itcm_TO_arb_itcm_SIG_in0_ack_src_id        ;
	wire [3:0]   itcm_TO_arb_itcm_SIG_in0_ack_tgt_id        ;
	wire         dec_fetch_TO_arb_itcm_SIG_out0_req_vld     ;
	wire [31:0]  dec_fetch_TO_arb_itcm_SIG_out0_req_addr    ;
	wire [31:0]  dec_fetch_TO_arb_itcm_SIG_out0_req_strb    ;
	wire [255:0] dec_fetch_TO_arb_itcm_SIG_out0_req_data    ;
	wire         dec_fetch_TO_arb_itcm_SIG_out0_req_opcode  ;
	wire [3:0]   dec_fetch_TO_arb_itcm_SIG_out0_req_src_id  ;
	wire [3:0]   dec_fetch_TO_arb_itcm_SIG_out0_req_tgt_id  ;
	wire [9:0]   dec_fetch_TO_arb_itcm_SIG_out0_req_sideband;
	wire         dec_lsu_TO_arb_itcm_SIG_out0_req_vld       ;
	wire [31:0]  dec_lsu_TO_arb_itcm_SIG_out0_req_addr      ;
	wire [31:0]  dec_lsu_TO_arb_itcm_SIG_out0_req_strb      ;
	wire [255:0] dec_lsu_TO_arb_itcm_SIG_out0_req_data      ;
	wire         dec_lsu_TO_arb_itcm_SIG_out0_req_opcode    ;
	wire [3:0]   dec_lsu_TO_arb_itcm_SIG_out0_req_src_id    ;
	wire [3:0]   dec_lsu_TO_arb_itcm_SIG_out0_req_tgt_id    ;
	wire [9:0]   dec_lsu_TO_arb_itcm_SIG_out0_req_sideband  ;
	wire         dec_fetch_TO_arb_itcm_SIG_out0_ack_rdy     ;
	wire         dec_lsu_TO_arb_itcm_SIG_out0_ack_rdy       ;

	//Wire define for Inout.

	//Wire sub module connect to this module and inter module connect.

	//Wire this module connect to sub module.

	//module inst.
	toy_bus_ToyCoreSlv_node_fetch_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck_forward_True fetch (
		.in0_req_vld(fetch_in0_req_vld),
		.in0_req_rdy(fetch_in0_req_rdy),
		.in0_req_addr(fetch_in0_req_addr),
		.in0_req_data(fetch_in0_req_data),
		.in0_req_strb(fetch_in0_req_strb),
		.in0_req_opcode(fetch_in0_req_opcode),
		.in0_req_sideband(fetch_in0_req_sideband),
		.in0_ack_vld(fetch_in0_ack_vld),
		.in0_ack_rdy(fetch_in0_ack_rdy),
		.in0_ack_data(fetch_in0_ack_data),
		.in0_ack_sideband(fetch_in0_ack_sideband),
		.out0_req_vld(fetch_TO_dec_fetch_SIG_out0_req_vld),
		.out0_req_rdy(dec_fetch_TO_fetch_SIG_in0_req_rdy),
		.out0_req_addr(fetch_TO_dec_fetch_SIG_out0_req_addr),
		.out0_req_strb(fetch_TO_dec_fetch_SIG_out0_req_strb),
		.out0_req_data(fetch_TO_dec_fetch_SIG_out0_req_data),
		.out0_req_opcode(fetch_TO_dec_fetch_SIG_out0_req_opcode),
		.out0_req_src_id(fetch_TO_dec_fetch_SIG_out0_req_src_id),
		.out0_req_tgt_id(fetch_TO_dec_fetch_SIG_out0_req_tgt_id),
		.out0_req_sideband(fetch_TO_dec_fetch_SIG_out0_req_sideband),
		.out0_ack_vld(dec_fetch_TO_fetch_SIG_in0_ack_vld),
		.out0_ack_rdy(fetch_TO_dec_fetch_SIG_out0_ack_rdy),
		.out0_ack_opcode(dec_fetch_TO_fetch_SIG_in0_ack_opcode),
		.out0_ack_data(dec_fetch_TO_fetch_SIG_in0_ack_data),
		.out0_ack_sideband(dec_fetch_TO_fetch_SIG_in0_ack_sideband),
		.out0_ack_src_id(dec_fetch_TO_fetch_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(dec_fetch_TO_fetch_SIG_in0_ack_tgt_id));
	toy_bus_ToyCoreSlv_node_lsu_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck_forward_True lsu (
		.in0_req_vld(lsu_in0_req_vld),
		.in0_req_rdy(lsu_in0_req_rdy),
		.in0_req_addr(lsu_in0_req_addr),
		.in0_req_data(lsu_in0_req_data),
		.in0_req_strb(lsu_in0_req_strb),
		.in0_req_opcode(lsu_in0_req_opcode),
		.in0_req_sideband(lsu_in0_req_sideband),
		.in0_ack_vld(lsu_in0_ack_vld),
		.in0_ack_rdy(lsu_in0_ack_rdy),
		.in0_ack_data(lsu_in0_ack_data),
		.in0_ack_sideband(lsu_in0_ack_sideband),
		.out0_req_vld(lsu_TO_dec_lsu_SIG_out0_req_vld),
		.out0_req_rdy(dec_lsu_TO_lsu_SIG_in0_req_rdy),
		.out0_req_addr(lsu_TO_dec_lsu_SIG_out0_req_addr),
		.out0_req_strb(lsu_TO_dec_lsu_SIG_out0_req_strb),
		.out0_req_data(lsu_TO_dec_lsu_SIG_out0_req_data),
		.out0_req_opcode(lsu_TO_dec_lsu_SIG_out0_req_opcode),
		.out0_req_src_id(lsu_TO_dec_lsu_SIG_out0_req_src_id),
		.out0_req_tgt_id(lsu_TO_dec_lsu_SIG_out0_req_tgt_id),
		.out0_req_sideband(lsu_TO_dec_lsu_SIG_out0_req_sideband),
		.out0_ack_vld(dec_lsu_TO_lsu_SIG_in0_ack_vld),
		.out0_ack_rdy(lsu_TO_dec_lsu_SIG_out0_ack_rdy),
		.out0_ack_opcode(dec_lsu_TO_lsu_SIG_in0_ack_opcode),
		.out0_ack_data(dec_lsu_TO_lsu_SIG_in0_ack_data),
		.out0_ack_sideband(dec_lsu_TO_lsu_SIG_in0_ack_sideband),
		.out0_ack_src_id(dec_lsu_TO_lsu_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(dec_lsu_TO_lsu_SIG_in0_ack_tgt_id));
	toy_bus_ToyMemMst_node_itcm_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck_forward_True itcm (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(arb_itcm_TO_itcm_SIG_out0_req_vld),
		.in0_req_rdy(itcm_TO_arb_itcm_SIG_in0_req_rdy),
		.in0_req_addr(arb_itcm_TO_itcm_SIG_out0_req_addr),
		.in0_req_strb(arb_itcm_TO_itcm_SIG_out0_req_strb),
		.in0_req_data(arb_itcm_TO_itcm_SIG_out0_req_data),
		.in0_req_opcode(arb_itcm_TO_itcm_SIG_out0_req_opcode),
		.in0_req_src_id(arb_itcm_TO_itcm_SIG_out0_req_src_id),
		.in0_req_tgt_id(arb_itcm_TO_itcm_SIG_out0_req_tgt_id),
		.in0_req_sideband(arb_itcm_TO_itcm_SIG_out0_req_sideband),
		.in0_ack_vld(itcm_TO_arb_itcm_SIG_in0_ack_vld),
		.in0_ack_rdy(arb_itcm_TO_itcm_SIG_out0_ack_rdy),
		.in0_ack_opcode(itcm_TO_arb_itcm_SIG_in0_ack_opcode),
		.in0_ack_data(itcm_TO_arb_itcm_SIG_in0_ack_data),
		.in0_ack_sideband(itcm_TO_arb_itcm_SIG_in0_ack_sideband),
		.in0_ack_src_id(itcm_TO_arb_itcm_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(itcm_TO_arb_itcm_SIG_in0_ack_tgt_id),
		.out0_mem_en(itcm_out0_mem_en),
		.out0_mem_addr(itcm_out0_mem_addr),
		.out0_mem_rd_data(itcm_out0_mem_rd_data),
		.out0_mem_wr_data(itcm_out0_mem_wr_data),
		.out0_mem_wr_byte_en(itcm_out0_mem_wr_byte_en),
		.out0_mem_wr_en(itcm_out0_mem_wr_en),
		.out0_mem_req_sideband(itcm_out0_mem_req_sideband),
		.out0_mem_ack_sideband(itcm_out0_mem_ack_sideband));
	toy_bus_ToyMemMst_node_dtcm_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck_forward_True dtcm (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(dec_dmem_TO_dtcm_SIG_out0_req_vld),
		.in0_req_rdy(dtcm_TO_dec_dmem_SIG_in0_req_rdy),
		.in0_req_addr(dec_dmem_TO_dtcm_SIG_out0_req_addr),
		.in0_req_strb(dec_dmem_TO_dtcm_SIG_out0_req_strb),
		.in0_req_data(dec_dmem_TO_dtcm_SIG_out0_req_data),
		.in0_req_opcode(dec_dmem_TO_dtcm_SIG_out0_req_opcode),
		.in0_req_src_id(dec_dmem_TO_dtcm_SIG_out0_req_src_id),
		.in0_req_tgt_id(dec_dmem_TO_dtcm_SIG_out0_req_tgt_id),
		.in0_req_sideband(dec_dmem_TO_dtcm_SIG_out0_req_sideband),
		.in0_ack_vld(dtcm_TO_dec_dmem_SIG_in0_ack_vld),
		.in0_ack_rdy(dec_dmem_TO_dtcm_SIG_out0_ack_rdy),
		.in0_ack_opcode(dtcm_TO_dec_dmem_SIG_in0_ack_opcode),
		.in0_ack_data(dtcm_TO_dec_dmem_SIG_in0_ack_data),
		.in0_ack_sideband(dtcm_TO_dec_dmem_SIG_in0_ack_sideband),
		.in0_ack_src_id(dtcm_TO_dec_dmem_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(dtcm_TO_dec_dmem_SIG_in0_ack_tgt_id),
		.out0_mem_en(dtcm_out0_mem_en),
		.out0_mem_addr(dtcm_out0_mem_addr),
		.out0_mem_rd_data(dtcm_out0_mem_rd_data),
		.out0_mem_wr_data(dtcm_out0_mem_wr_data),
		.out0_mem_wr_byte_en(dtcm_out0_mem_wr_byte_en),
		.out0_mem_wr_en(dtcm_out0_mem_wr_en),
		.out0_mem_req_sideband(dtcm_out0_mem_req_sideband),
		.out0_mem_ack_sideband(dtcm_out0_mem_ack_sideband));
	toy_bus_ToyMemMst_node_eslv_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck_forward_True eslv (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(dec_dmem_TO_eslv_SIG_out1_req_vld),
		.in0_req_rdy(eslv_TO_dec_dmem_SIG_in0_req_rdy),
		.in0_req_addr(dec_dmem_TO_eslv_SIG_out1_req_addr),
		.in0_req_strb(dec_dmem_TO_eslv_SIG_out1_req_strb),
		.in0_req_data(dec_dmem_TO_eslv_SIG_out1_req_data),
		.in0_req_opcode(dec_dmem_TO_eslv_SIG_out1_req_opcode),
		.in0_req_src_id(dec_dmem_TO_eslv_SIG_out1_req_src_id),
		.in0_req_tgt_id(dec_dmem_TO_eslv_SIG_out1_req_tgt_id),
		.in0_req_sideband(dec_dmem_TO_eslv_SIG_out1_req_sideband),
		.in0_ack_vld(eslv_TO_dec_dmem_SIG_in0_ack_vld),
		.in0_ack_rdy(dec_dmem_TO_eslv_SIG_out1_ack_rdy),
		.in0_ack_opcode(eslv_TO_dec_dmem_SIG_in0_ack_opcode),
		.in0_ack_data(eslv_TO_dec_dmem_SIG_in0_ack_data),
		.in0_ack_sideband(eslv_TO_dec_dmem_SIG_in0_ack_sideband),
		.in0_ack_src_id(eslv_TO_dec_dmem_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(eslv_TO_dec_dmem_SIG_in0_ack_tgt_id),
		.out0_mem_en(eslv_out0_mem_en),
		.out0_mem_addr(eslv_out0_mem_addr),
		.out0_mem_rd_data(eslv_out0_mem_rd_data),
		.out0_mem_wr_data(eslv_out0_mem_wr_data),
		.out0_mem_wr_byte_en(eslv_out0_mem_wr_byte_en),
		.out0_mem_wr_en(eslv_out0_mem_wr_en),
		.out0_mem_req_sideband(eslv_out0_mem_req_sideband),
		.out0_mem_ack_sideband(eslv_out0_mem_ack_sideband));
	toy_bus_DDec2ch_node_dec_fetch_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck dec_fetch (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(fetch_TO_dec_fetch_SIG_out0_req_vld),
		.in0_req_rdy(dec_fetch_TO_fetch_SIG_in0_req_rdy),
		.in0_req_addr(fetch_TO_dec_fetch_SIG_out0_req_addr),
		.in0_req_strb(fetch_TO_dec_fetch_SIG_out0_req_strb),
		.in0_req_data(fetch_TO_dec_fetch_SIG_out0_req_data),
		.in0_req_opcode(fetch_TO_dec_fetch_SIG_out0_req_opcode),
		.in0_req_src_id(fetch_TO_dec_fetch_SIG_out0_req_src_id),
		.in0_req_tgt_id(fetch_TO_dec_fetch_SIG_out0_req_tgt_id),
		.in0_req_sideband(fetch_TO_dec_fetch_SIG_out0_req_sideband),
		.in0_ack_vld(dec_fetch_TO_fetch_SIG_in0_ack_vld),
		.in0_ack_rdy(fetch_TO_dec_fetch_SIG_out0_ack_rdy),
		.in0_ack_opcode(dec_fetch_TO_fetch_SIG_in0_ack_opcode),
		.in0_ack_data(dec_fetch_TO_fetch_SIG_in0_ack_data),
		.in0_ack_sideband(dec_fetch_TO_fetch_SIG_in0_ack_sideband),
		.in0_ack_src_id(dec_fetch_TO_fetch_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(dec_fetch_TO_fetch_SIG_in0_ack_tgt_id),
		.out0_req_vld(dec_fetch_TO_arb_itcm_SIG_out0_req_vld),
		.out0_req_rdy(arb_itcm_TO_dec_fetch_SIG_in0_req_rdy),
		.out0_req_addr(dec_fetch_TO_arb_itcm_SIG_out0_req_addr),
		.out0_req_strb(dec_fetch_TO_arb_itcm_SIG_out0_req_strb),
		.out0_req_data(dec_fetch_TO_arb_itcm_SIG_out0_req_data),
		.out0_req_opcode(dec_fetch_TO_arb_itcm_SIG_out0_req_opcode),
		.out0_req_src_id(dec_fetch_TO_arb_itcm_SIG_out0_req_src_id),
		.out0_req_tgt_id(dec_fetch_TO_arb_itcm_SIG_out0_req_tgt_id),
		.out0_req_sideband(dec_fetch_TO_arb_itcm_SIG_out0_req_sideband),
		.out1_req_vld(dec_fetch_TO_arb_dtcm_SIG_out1_req_vld),
		.out1_req_rdy(arb_dtcm_TO_dec_fetch_SIG_in0_req_rdy),
		.out1_req_addr(dec_fetch_TO_arb_dtcm_SIG_out1_req_addr),
		.out1_req_strb(dec_fetch_TO_arb_dtcm_SIG_out1_req_strb),
		.out1_req_data(dec_fetch_TO_arb_dtcm_SIG_out1_req_data),
		.out1_req_opcode(dec_fetch_TO_arb_dtcm_SIG_out1_req_opcode),
		.out1_req_src_id(dec_fetch_TO_arb_dtcm_SIG_out1_req_src_id),
		.out1_req_tgt_id(dec_fetch_TO_arb_dtcm_SIG_out1_req_tgt_id),
		.out1_req_sideband(dec_fetch_TO_arb_dtcm_SIG_out1_req_sideband),
		.out0_ack_vld(arb_itcm_TO_dec_fetch_SIG_in0_ack_vld),
		.out0_ack_rdy(dec_fetch_TO_arb_itcm_SIG_out0_ack_rdy),
		.out0_ack_opcode(arb_itcm_TO_dec_fetch_SIG_in0_ack_opcode),
		.out0_ack_data(arb_itcm_TO_dec_fetch_SIG_in0_ack_data),
		.out0_ack_sideband(arb_itcm_TO_dec_fetch_SIG_in0_ack_sideband),
		.out0_ack_src_id(arb_itcm_TO_dec_fetch_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(arb_itcm_TO_dec_fetch_SIG_in0_ack_tgt_id),
		.out1_ack_vld(arb_dtcm_TO_dec_fetch_SIG_in0_ack_vld),
		.out1_ack_rdy(dec_fetch_TO_arb_dtcm_SIG_out1_ack_rdy),
		.out1_ack_opcode(arb_dtcm_TO_dec_fetch_SIG_in0_ack_opcode),
		.out1_ack_data(arb_dtcm_TO_dec_fetch_SIG_in0_ack_data),
		.out1_ack_sideband(arb_dtcm_TO_dec_fetch_SIG_in0_ack_sideband),
		.out1_ack_src_id(arb_dtcm_TO_dec_fetch_SIG_in0_ack_src_id),
		.out1_ack_tgt_id(arb_dtcm_TO_dec_fetch_SIG_in0_ack_tgt_id));
	toy_bus_DDec2ch_node_dec_lsu_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck dec_lsu (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(lsu_TO_dec_lsu_SIG_out0_req_vld),
		.in0_req_rdy(dec_lsu_TO_lsu_SIG_in0_req_rdy),
		.in0_req_addr(lsu_TO_dec_lsu_SIG_out0_req_addr),
		.in0_req_strb(lsu_TO_dec_lsu_SIG_out0_req_strb),
		.in0_req_data(lsu_TO_dec_lsu_SIG_out0_req_data),
		.in0_req_opcode(lsu_TO_dec_lsu_SIG_out0_req_opcode),
		.in0_req_src_id(lsu_TO_dec_lsu_SIG_out0_req_src_id),
		.in0_req_tgt_id(lsu_TO_dec_lsu_SIG_out0_req_tgt_id),
		.in0_req_sideband(lsu_TO_dec_lsu_SIG_out0_req_sideband),
		.in0_ack_vld(dec_lsu_TO_lsu_SIG_in0_ack_vld),
		.in0_ack_rdy(lsu_TO_dec_lsu_SIG_out0_ack_rdy),
		.in0_ack_opcode(dec_lsu_TO_lsu_SIG_in0_ack_opcode),
		.in0_ack_data(dec_lsu_TO_lsu_SIG_in0_ack_data),
		.in0_ack_sideband(dec_lsu_TO_lsu_SIG_in0_ack_sideband),
		.in0_ack_src_id(dec_lsu_TO_lsu_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(dec_lsu_TO_lsu_SIG_in0_ack_tgt_id),
		.out0_req_vld(dec_lsu_TO_arb_itcm_SIG_out0_req_vld),
		.out0_req_rdy(arb_itcm_TO_dec_lsu_SIG_in1_req_rdy),
		.out0_req_addr(dec_lsu_TO_arb_itcm_SIG_out0_req_addr),
		.out0_req_strb(dec_lsu_TO_arb_itcm_SIG_out0_req_strb),
		.out0_req_data(dec_lsu_TO_arb_itcm_SIG_out0_req_data),
		.out0_req_opcode(dec_lsu_TO_arb_itcm_SIG_out0_req_opcode),
		.out0_req_src_id(dec_lsu_TO_arb_itcm_SIG_out0_req_src_id),
		.out0_req_tgt_id(dec_lsu_TO_arb_itcm_SIG_out0_req_tgt_id),
		.out0_req_sideband(dec_lsu_TO_arb_itcm_SIG_out0_req_sideband),
		.out1_req_vld(dec_lsu_TO_arb_dtcm_SIG_out1_req_vld),
		.out1_req_rdy(arb_dtcm_TO_dec_lsu_SIG_in1_req_rdy),
		.out1_req_addr(dec_lsu_TO_arb_dtcm_SIG_out1_req_addr),
		.out1_req_strb(dec_lsu_TO_arb_dtcm_SIG_out1_req_strb),
		.out1_req_data(dec_lsu_TO_arb_dtcm_SIG_out1_req_data),
		.out1_req_opcode(dec_lsu_TO_arb_dtcm_SIG_out1_req_opcode),
		.out1_req_src_id(dec_lsu_TO_arb_dtcm_SIG_out1_req_src_id),
		.out1_req_tgt_id(dec_lsu_TO_arb_dtcm_SIG_out1_req_tgt_id),
		.out1_req_sideband(dec_lsu_TO_arb_dtcm_SIG_out1_req_sideband),
		.out0_ack_vld(arb_itcm_TO_dec_lsu_SIG_in1_ack_vld),
		.out0_ack_rdy(dec_lsu_TO_arb_itcm_SIG_out0_ack_rdy),
		.out0_ack_opcode(arb_itcm_TO_dec_lsu_SIG_in1_ack_opcode),
		.out0_ack_data(arb_itcm_TO_dec_lsu_SIG_in1_ack_data),
		.out0_ack_sideband(arb_itcm_TO_dec_lsu_SIG_in1_ack_sideband),
		.out0_ack_src_id(arb_itcm_TO_dec_lsu_SIG_in1_ack_src_id),
		.out0_ack_tgt_id(arb_itcm_TO_dec_lsu_SIG_in1_ack_tgt_id),
		.out1_ack_vld(arb_dtcm_TO_dec_lsu_SIG_in1_ack_vld),
		.out1_ack_rdy(dec_lsu_TO_arb_dtcm_SIG_out1_ack_rdy),
		.out1_ack_opcode(arb_dtcm_TO_dec_lsu_SIG_in1_ack_opcode),
		.out1_ack_data(arb_dtcm_TO_dec_lsu_SIG_in1_ack_data),
		.out1_ack_sideband(arb_dtcm_TO_dec_lsu_SIG_in1_ack_sideband),
		.out1_ack_src_id(arb_dtcm_TO_dec_lsu_SIG_in1_ack_src_id),
		.out1_ack_tgt_id(arb_dtcm_TO_dec_lsu_SIG_in1_ack_tgt_id));
	toy_bus_DDec2ch_node_dec_dmem_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck dec_dmem (
		.clk(clk),
		.rst_n(rst_n),
		.in0_req_vld(arb_dtcm_TO_dec_dmem_SIG_out0_req_vld),
		.in0_req_rdy(dec_dmem_TO_arb_dtcm_SIG_in0_req_rdy),
		.in0_req_addr(arb_dtcm_TO_dec_dmem_SIG_out0_req_addr),
		.in0_req_strb(arb_dtcm_TO_dec_dmem_SIG_out0_req_strb),
		.in0_req_data(arb_dtcm_TO_dec_dmem_SIG_out0_req_data),
		.in0_req_opcode(arb_dtcm_TO_dec_dmem_SIG_out0_req_opcode),
		.in0_req_src_id(arb_dtcm_TO_dec_dmem_SIG_out0_req_src_id),
		.in0_req_tgt_id(arb_dtcm_TO_dec_dmem_SIG_out0_req_tgt_id),
		.in0_req_sideband(arb_dtcm_TO_dec_dmem_SIG_out0_req_sideband),
		.in0_ack_vld(dec_dmem_TO_arb_dtcm_SIG_in0_ack_vld),
		.in0_ack_rdy(arb_dtcm_TO_dec_dmem_SIG_out0_ack_rdy),
		.in0_ack_opcode(dec_dmem_TO_arb_dtcm_SIG_in0_ack_opcode),
		.in0_ack_data(dec_dmem_TO_arb_dtcm_SIG_in0_ack_data),
		.in0_ack_sideband(dec_dmem_TO_arb_dtcm_SIG_in0_ack_sideband),
		.in0_ack_src_id(dec_dmem_TO_arb_dtcm_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(dec_dmem_TO_arb_dtcm_SIG_in0_ack_tgt_id),
		.out0_req_vld(dec_dmem_TO_dtcm_SIG_out0_req_vld),
		.out0_req_rdy(dtcm_TO_dec_dmem_SIG_in0_req_rdy),
		.out0_req_addr(dec_dmem_TO_dtcm_SIG_out0_req_addr),
		.out0_req_strb(dec_dmem_TO_dtcm_SIG_out0_req_strb),
		.out0_req_data(dec_dmem_TO_dtcm_SIG_out0_req_data),
		.out0_req_opcode(dec_dmem_TO_dtcm_SIG_out0_req_opcode),
		.out0_req_src_id(dec_dmem_TO_dtcm_SIG_out0_req_src_id),
		.out0_req_tgt_id(dec_dmem_TO_dtcm_SIG_out0_req_tgt_id),
		.out0_req_sideband(dec_dmem_TO_dtcm_SIG_out0_req_sideband),
		.out1_req_vld(dec_dmem_TO_eslv_SIG_out1_req_vld),
		.out1_req_rdy(eslv_TO_dec_dmem_SIG_in0_req_rdy),
		.out1_req_addr(dec_dmem_TO_eslv_SIG_out1_req_addr),
		.out1_req_strb(dec_dmem_TO_eslv_SIG_out1_req_strb),
		.out1_req_data(dec_dmem_TO_eslv_SIG_out1_req_data),
		.out1_req_opcode(dec_dmem_TO_eslv_SIG_out1_req_opcode),
		.out1_req_src_id(dec_dmem_TO_eslv_SIG_out1_req_src_id),
		.out1_req_tgt_id(dec_dmem_TO_eslv_SIG_out1_req_tgt_id),
		.out1_req_sideband(dec_dmem_TO_eslv_SIG_out1_req_sideband),
		.out0_ack_vld(dtcm_TO_dec_dmem_SIG_in0_ack_vld),
		.out0_ack_rdy(dec_dmem_TO_dtcm_SIG_out0_ack_rdy),
		.out0_ack_opcode(dtcm_TO_dec_dmem_SIG_in0_ack_opcode),
		.out0_ack_data(dtcm_TO_dec_dmem_SIG_in0_ack_data),
		.out0_ack_sideband(dtcm_TO_dec_dmem_SIG_in0_ack_sideband),
		.out0_ack_src_id(dtcm_TO_dec_dmem_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(dtcm_TO_dec_dmem_SIG_in0_ack_tgt_id),
		.out1_ack_vld(eslv_TO_dec_dmem_SIG_in0_ack_vld),
		.out1_ack_rdy(dec_dmem_TO_eslv_SIG_out1_ack_rdy),
		.out1_ack_opcode(eslv_TO_dec_dmem_SIG_in0_ack_opcode),
		.out1_ack_data(eslv_TO_dec_dmem_SIG_in0_ack_data),
		.out1_ack_sideband(eslv_TO_dec_dmem_SIG_in0_ack_sideband),
		.out1_ack_src_id(eslv_TO_dec_dmem_SIG_in0_ack_src_id),
		.out1_ack_tgt_id(eslv_TO_dec_dmem_SIG_in0_ack_tgt_id));
	toy_bus_DArb2ch_node_arb_dtcm_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck arb_dtcm (
		.clk(clk),
		.rst_n(rst_n),
		.out0_req_vld(arb_dtcm_TO_dec_dmem_SIG_out0_req_vld),
		.out0_req_rdy(dec_dmem_TO_arb_dtcm_SIG_in0_req_rdy),
		.out0_req_addr(arb_dtcm_TO_dec_dmem_SIG_out0_req_addr),
		.out0_req_strb(arb_dtcm_TO_dec_dmem_SIG_out0_req_strb),
		.out0_req_data(arb_dtcm_TO_dec_dmem_SIG_out0_req_data),
		.out0_req_opcode(arb_dtcm_TO_dec_dmem_SIG_out0_req_opcode),
		.out0_req_src_id(arb_dtcm_TO_dec_dmem_SIG_out0_req_src_id),
		.out0_req_tgt_id(arb_dtcm_TO_dec_dmem_SIG_out0_req_tgt_id),
		.out0_req_sideband(arb_dtcm_TO_dec_dmem_SIG_out0_req_sideband),
		.out0_ack_vld(dec_dmem_TO_arb_dtcm_SIG_in0_ack_vld),
		.out0_ack_rdy(arb_dtcm_TO_dec_dmem_SIG_out0_ack_rdy),
		.out0_ack_opcode(dec_dmem_TO_arb_dtcm_SIG_in0_ack_opcode),
		.out0_ack_data(dec_dmem_TO_arb_dtcm_SIG_in0_ack_data),
		.out0_ack_sideband(dec_dmem_TO_arb_dtcm_SIG_in0_ack_sideband),
		.out0_ack_src_id(dec_dmem_TO_arb_dtcm_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(dec_dmem_TO_arb_dtcm_SIG_in0_ack_tgt_id),
		.in0_req_vld(dec_fetch_TO_arb_dtcm_SIG_out1_req_vld),
		.in0_req_rdy(arb_dtcm_TO_dec_fetch_SIG_in0_req_rdy),
		.in0_req_addr(dec_fetch_TO_arb_dtcm_SIG_out1_req_addr),
		.in0_req_strb(dec_fetch_TO_arb_dtcm_SIG_out1_req_strb),
		.in0_req_data(dec_fetch_TO_arb_dtcm_SIG_out1_req_data),
		.in0_req_opcode(dec_fetch_TO_arb_dtcm_SIG_out1_req_opcode),
		.in0_req_src_id(dec_fetch_TO_arb_dtcm_SIG_out1_req_src_id),
		.in0_req_tgt_id(dec_fetch_TO_arb_dtcm_SIG_out1_req_tgt_id),
		.in0_req_sideband(dec_fetch_TO_arb_dtcm_SIG_out1_req_sideband),
		.in1_req_vld(dec_lsu_TO_arb_dtcm_SIG_out1_req_vld),
		.in1_req_rdy(arb_dtcm_TO_dec_lsu_SIG_in1_req_rdy),
		.in1_req_addr(dec_lsu_TO_arb_dtcm_SIG_out1_req_addr),
		.in1_req_strb(dec_lsu_TO_arb_dtcm_SIG_out1_req_strb),
		.in1_req_data(dec_lsu_TO_arb_dtcm_SIG_out1_req_data),
		.in1_req_opcode(dec_lsu_TO_arb_dtcm_SIG_out1_req_opcode),
		.in1_req_src_id(dec_lsu_TO_arb_dtcm_SIG_out1_req_src_id),
		.in1_req_tgt_id(dec_lsu_TO_arb_dtcm_SIG_out1_req_tgt_id),
		.in1_req_sideband(dec_lsu_TO_arb_dtcm_SIG_out1_req_sideband),
		.in0_ack_vld(arb_dtcm_TO_dec_fetch_SIG_in0_ack_vld),
		.in0_ack_rdy(dec_fetch_TO_arb_dtcm_SIG_out1_ack_rdy),
		.in0_ack_opcode(arb_dtcm_TO_dec_fetch_SIG_in0_ack_opcode),
		.in0_ack_data(arb_dtcm_TO_dec_fetch_SIG_in0_ack_data),
		.in0_ack_sideband(arb_dtcm_TO_dec_fetch_SIG_in0_ack_sideband),
		.in0_ack_src_id(arb_dtcm_TO_dec_fetch_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(arb_dtcm_TO_dec_fetch_SIG_in0_ack_tgt_id),
		.in1_ack_vld(arb_dtcm_TO_dec_lsu_SIG_in1_ack_vld),
		.in1_ack_rdy(dec_lsu_TO_arb_dtcm_SIG_out1_ack_rdy),
		.in1_ack_opcode(arb_dtcm_TO_dec_lsu_SIG_in1_ack_opcode),
		.in1_ack_data(arb_dtcm_TO_dec_lsu_SIG_in1_ack_data),
		.in1_ack_sideband(arb_dtcm_TO_dec_lsu_SIG_in1_ack_sideband),
		.in1_ack_src_id(arb_dtcm_TO_dec_lsu_SIG_in1_ack_src_id),
		.in1_ack_tgt_id(arb_dtcm_TO_dec_lsu_SIG_in1_ack_tgt_id));
	toy_bus_DArb2ch_node_arb_itcm_fwd_pld_type_ToyBusReq_bwd_pld_type_ToyBusAck arb_itcm (
		.clk(clk),
		.rst_n(rst_n),
		.out0_req_vld(arb_itcm_TO_itcm_SIG_out0_req_vld),
		.out0_req_rdy(itcm_TO_arb_itcm_SIG_in0_req_rdy),
		.out0_req_addr(arb_itcm_TO_itcm_SIG_out0_req_addr),
		.out0_req_strb(arb_itcm_TO_itcm_SIG_out0_req_strb),
		.out0_req_data(arb_itcm_TO_itcm_SIG_out0_req_data),
		.out0_req_opcode(arb_itcm_TO_itcm_SIG_out0_req_opcode),
		.out0_req_src_id(arb_itcm_TO_itcm_SIG_out0_req_src_id),
		.out0_req_tgt_id(arb_itcm_TO_itcm_SIG_out0_req_tgt_id),
		.out0_req_sideband(arb_itcm_TO_itcm_SIG_out0_req_sideband),
		.out0_ack_vld(itcm_TO_arb_itcm_SIG_in0_ack_vld),
		.out0_ack_rdy(arb_itcm_TO_itcm_SIG_out0_ack_rdy),
		.out0_ack_opcode(itcm_TO_arb_itcm_SIG_in0_ack_opcode),
		.out0_ack_data(itcm_TO_arb_itcm_SIG_in0_ack_data),
		.out0_ack_sideband(itcm_TO_arb_itcm_SIG_in0_ack_sideband),
		.out0_ack_src_id(itcm_TO_arb_itcm_SIG_in0_ack_src_id),
		.out0_ack_tgt_id(itcm_TO_arb_itcm_SIG_in0_ack_tgt_id),
		.in0_req_vld(dec_fetch_TO_arb_itcm_SIG_out0_req_vld),
		.in0_req_rdy(arb_itcm_TO_dec_fetch_SIG_in0_req_rdy),
		.in0_req_addr(dec_fetch_TO_arb_itcm_SIG_out0_req_addr),
		.in0_req_strb(dec_fetch_TO_arb_itcm_SIG_out0_req_strb),
		.in0_req_data(dec_fetch_TO_arb_itcm_SIG_out0_req_data),
		.in0_req_opcode(dec_fetch_TO_arb_itcm_SIG_out0_req_opcode),
		.in0_req_src_id(dec_fetch_TO_arb_itcm_SIG_out0_req_src_id),
		.in0_req_tgt_id(dec_fetch_TO_arb_itcm_SIG_out0_req_tgt_id),
		.in0_req_sideband(dec_fetch_TO_arb_itcm_SIG_out0_req_sideband),
		.in1_req_vld(dec_lsu_TO_arb_itcm_SIG_out0_req_vld),
		.in1_req_rdy(arb_itcm_TO_dec_lsu_SIG_in1_req_rdy),
		.in1_req_addr(dec_lsu_TO_arb_itcm_SIG_out0_req_addr),
		.in1_req_strb(dec_lsu_TO_arb_itcm_SIG_out0_req_strb),
		.in1_req_data(dec_lsu_TO_arb_itcm_SIG_out0_req_data),
		.in1_req_opcode(dec_lsu_TO_arb_itcm_SIG_out0_req_opcode),
		.in1_req_src_id(dec_lsu_TO_arb_itcm_SIG_out0_req_src_id),
		.in1_req_tgt_id(dec_lsu_TO_arb_itcm_SIG_out0_req_tgt_id),
		.in1_req_sideband(dec_lsu_TO_arb_itcm_SIG_out0_req_sideband),
		.in0_ack_vld(arb_itcm_TO_dec_fetch_SIG_in0_ack_vld),
		.in0_ack_rdy(dec_fetch_TO_arb_itcm_SIG_out0_ack_rdy),
		.in0_ack_opcode(arb_itcm_TO_dec_fetch_SIG_in0_ack_opcode),
		.in0_ack_data(arb_itcm_TO_dec_fetch_SIG_in0_ack_data),
		.in0_ack_sideband(arb_itcm_TO_dec_fetch_SIG_in0_ack_sideband),
		.in0_ack_src_id(arb_itcm_TO_dec_fetch_SIG_in0_ack_src_id),
		.in0_ack_tgt_id(arb_itcm_TO_dec_fetch_SIG_in0_ack_tgt_id),
		.in1_ack_vld(arb_itcm_TO_dec_lsu_SIG_in1_ack_vld),
		.in1_ack_rdy(dec_lsu_TO_arb_itcm_SIG_out0_ack_rdy),
		.in1_ack_opcode(arb_itcm_TO_dec_lsu_SIG_in1_ack_opcode),
		.in1_ack_data(arb_itcm_TO_dec_lsu_SIG_in1_ack_data),
		.in1_ack_sideband(arb_itcm_TO_dec_lsu_SIG_in1_ack_sideband),
		.in1_ack_src_id(arb_itcm_TO_dec_lsu_SIG_in1_ack_src_id),
		.in1_ack_tgt_id(arb_itcm_TO_dec_lsu_SIG_in1_ack_tgt_id));

endmodule
//[UHDL]Content End [md5:2111b132991b4982eb07c16fec96a000]

