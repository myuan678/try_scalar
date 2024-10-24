

module toy_scalar
    import toy_pack::*;
    (
     input  logic                        clk                       ,
     input  logic                        rst_n                     ,

     // for icache
     input   logic                            fetch_mem_ack_vld      ,
     output  logic                            fetch_mem_ack_rdy      ,
     input   logic [FETCH_DATA_WIDTH-1:0]     fetch_mem_ack_data     ,
     input   logic [ROB_ENTRY_ID_WIDTH-1:0]   fetch_mem_ack_entry_id ,
     output  logic [ROB_ENTRY_ID_WIDTH-1:0]   fetch_mem_req_entry_id ,
     output  logic [ADDR_WIDTH-1:0]           fetch_mem_req_addr     ,
     output  logic                            fetch_mem_req_vld      ,
     input   logic                            fetch_mem_req_rdy      ,

     // for itcm
     output  logic [ADDR_WIDTH-1:0]          inst_mem_addr           ,
     input   logic [BUS_DATA_WIDTH-1:0]      inst_mem_rd_data        ,
     output  logic [BUS_DATA_WIDTH-1:0]      inst_mem_wr_data        ,
     output  logic [BUS_DATA_WIDTH/8-1:0]    inst_mem_wr_byte_en     ,
     output  logic                           inst_mem_wr_en          ,
     output  logic                           inst_mem_en             ,
     output  logic [FETCH_SB_WIDTH-1:0]      inst_mem_req_sideband   ,
     input   logic [FETCH_SB_WIDTH-1:0]      inst_mem_ack_sideband   ,

     // for dtcm
     output   logic [ADDR_WIDTH-1:0]         dtcm_mem_addr           ,
     input    logic [BUS_DATA_WIDTH-1:0]     dtcm_mem_rd_data        ,
     output   logic [BUS_DATA_WIDTH-1:0]     dtcm_mem_wr_data        ,
     output   logic [BUS_DATA_WIDTH/8-1:0]   dtcm_mem_wr_byte_en     ,
     output   logic                          dtcm_mem_wr_en          ,
     output   logic                          dtcm_mem_en             ,
     output   logic [FETCH_SB_WIDTH-1:0]     dtcm_mem_req_sideband   ,
     input    logic [FETCH_SB_WIDTH-1:0]     dtcm_mem_ack_sideband   ,

     output logic [ADDR_WIDTH-1:0]       ext_mem_addr              ,
     input  logic [BUS_DATA_WIDTH-1:0]   ext_mem_rd_data           ,
     output logic [BUS_DATA_WIDTH-1:0]   ext_mem_wr_data           ,
     output logic [BUS_DATA_WIDTH/8-1:0] ext_mem_wr_byte_en        ,
     output logic                        ext_mem_wr_en             ,
     output logic                        ext_mem_en                ,

     output logic                        custom_instruction_vld    ,
     input  logic                        custom_instruction_rdy    ,
     output logic [INST_WIDTH-1:0]       custom_instruction_pld    ,
     output logic [REG_WIDTH-1:0]        custom_rs1_val            ,
     output logic [REG_WIDTH-1:0]        custom_rs2_val            ,
     output logic [ADDR_WIDTH-1:0]       custom_pc                 ,

     input  logic                        intr_meip                 ,
     input  logic                        intr_msip
    );
    
//=================================================================
// Logic
//=================================================================
    

    logic                           lsu_mem_req_vld         ;
    logic                           lsu_mem_req_rdy         ;
    logic [ADDR_WIDTH-1:0]          lsu_mem_req_addr        ;
    logic [DATA_WIDTH-1:0]          lsu_mem_req_data        ;
    logic [DATA_WIDTH/8-1:0]        lsu_mem_req_strb        ;
    logic                           lsu_mem_req_opcode      ;
    logic                           lsu_mem_ack_vld         ;
    logic                           lsu_mem_ack_rdy         ;
    logic [DATA_WIDTH-1:0]          lsu_mem_ack_data        ;
    logic [FETCH_SB_WIDTH-1:0]      lsu_mem_req_sideband    ;
    logic [FETCH_SB_WIDTH-1:0]      lsu_mem_ack_sideband    ;
    
    // logic [ADDR_WIDTH-1:0]          inst_mem_addr           ;
    // logic [BUS_DATA_WIDTH-1:0]      inst_mem_rd_data        ;
    // logic [BUS_DATA_WIDTH-1:0]      inst_mem_wr_data        ;
    // logic [BUS_DATA_WIDTH/8-1:0]    inst_mem_wr_byte_en     ;
    // logic                           inst_mem_wr_en          ;
    // logic                           inst_mem_en             ;
    // logic [FETCH_SB_WIDTH-1:0]      inst_mem_req_sideband   ;
    // logic [FETCH_SB_WIDTH-1:0]      inst_mem_ack_sideband   ;

    // logic [ADDR_WIDTH-1:0]          dtcm_mem_addr           ;
    // logic [BUS_DATA_WIDTH-1:0]      dtcm_mem_wr_data        ;
    // logic [BUS_DATA_WIDTH-1:0]      dtcm_mem_rd_data        ;
    // logic [BUS_DATA_WIDTH/8-1:0]    dtcm_mem_wr_byte_en     ;
    // logic                           dtcm_mem_wr_en          ;
    // logic                           dtcm_mem_en             ;
    // logic [FETCH_SB_WIDTH-1:0]      dtcm_mem_req_sideband   ;
    // logic [FETCH_SB_WIDTH-1:0]      dtcm_mem_ack_sideband   ;

//=================================================================
// Core
//=================================================================

    toy_core u_core(
                    .clk                    (clk                    ),
                    .rst_n                  (rst_n                  ),

                    .fetch_mem_ack_vld      (fetch_mem_ack_vld     ),
                    .fetch_mem_ack_rdy      (fetch_mem_ack_rdy     ),
                    .fetch_mem_ack_data     (fetch_mem_ack_data    ),
                    .fetch_mem_ack_entry_id (fetch_mem_ack_entry_id),
                    .fetch_mem_req_addr     (fetch_mem_req_addr    ),
                    .fetch_mem_req_vld      (fetch_mem_req_vld     ),
                    .fetch_mem_req_rdy      (fetch_mem_req_rdy     ),
                    .fetch_mem_req_entry_id (fetch_mem_req_entry_id),

                    .lsu_mem_req_vld        (lsu_mem_req_vld        ),
                    .lsu_mem_req_rdy        (lsu_mem_req_rdy        ),
                    .lsu_mem_req_addr       (lsu_mem_req_addr       ),
                    .lsu_mem_req_data       (lsu_mem_req_data       ),
                    .lsu_mem_req_strb       (lsu_mem_req_strb       ),
                    .lsu_mem_req_opcode     (lsu_mem_req_opcode     ),
                    .lsu_mem_req_sideband   (lsu_mem_req_sideband   ),
                    .lsu_mem_ack_sideband   (lsu_mem_ack_sideband   ),
                    .lsu_mem_ack_vld        (lsu_mem_ack_vld        ),
                    .lsu_mem_ack_rdy        (lsu_mem_ack_rdy        ),
                    .lsu_mem_ack_data       (lsu_mem_ack_data       ),

                    .custom_instruction_vld (custom_instruction_vld ),
                    .custom_instruction_rdy (custom_instruction_rdy ),
                    .custom_instruction_pld (custom_instruction_pld ),
                    .custom_rs1_val         (custom_rs1_val         ),
                    .custom_rs2_val         (custom_rs2_val         ),
                    .custom_pc              (custom_pc              ),

                    .intr_meip              (intr_meip              ),
                    .intr_msip              (intr_msip              )
                   );

    // toy_itcm u_itcm (
    //                  .clk                   (clk                   ),
    //                  .fetch_mem_ack_vld     (fetch_mem_ack_vld     ),
    //                  .fetch_mem_ack_rdy     (fetch_mem_ack_rdy     ),
    //                  .fetch_mem_ack_data    (fetch_mem_ack_data    ),
    //                  .fetch_mem_ack_entry_id(fetch_mem_ack_entry_id),
    //                  .fetch_mem_req_addr    (fetch_mem_req_addr    ),
    //                  .fetch_mem_req_vld     (fetch_mem_req_vld     ),
    //                  .fetch_mem_req_rdy     (fetch_mem_req_rdy     ),
    //                  .fetch_mem_req_entry_id(fetch_mem_req_entry_id)
    //                 ); 

// //============================================================
// // Memory
// //============================================================
//     toy_mem_top u_toy_mem_top(

//                               .clk                        (clk                   ),
//                               .rst_n                      (rst_n                 ),
//                               .inst_mem_addr              (inst_mem_addr         ), 
//                               .inst_mem_rd_data           (inst_mem_rd_data      ), 
//                               .inst_mem_wr_data           (inst_mem_wr_data      ), 
//                               .inst_mem_wr_byte_en        (inst_mem_wr_byte_en   ), 
//                               .inst_mem_wr_en             (inst_mem_wr_en        ), 
//                               .inst_mem_en                (inst_mem_en           ), 
//                               .inst_mem_req_sideband      (inst_mem_req_sideband ), 
//                               .inst_mem_ack_sideband      (inst_mem_ack_sideband ), 
//                               .dtcm_mem_addr              (dtcm_mem_addr         ), 
//                               .dtcm_mem_wr_data           (dtcm_mem_wr_data      ), 
//                               .dtcm_mem_rd_data           (dtcm_mem_rd_data      ), 
//                               .dtcm_mem_wr_byte_en        (dtcm_mem_wr_byte_en   ), 
//                               .dtcm_mem_wr_en             (dtcm_mem_wr_en        ), 
//                               .dtcm_mem_en                (dtcm_mem_en           ), 
//                               .dtcm_mem_req_sideband      (dtcm_mem_req_sideband ), 
//                               .dtcm_mem_ack_sideband      (dtcm_mem_ack_sideband )

//                              );
//=================================================================
// Bus
//=================================================================

    toy_bus_DWrap_network_toy_bus u_bus (
                                         .clk                        (clk                        ),
                                         .rst_n                      (rst_n                      ),

                                         .fetch_in0_req_vld          (1'b0                         ),
                                         .fetch_in0_req_rdy          (                             ),
                                         .fetch_in0_req_addr         (32'b0                        ),
                                         .fetch_in0_req_data         ({BUS_DATA_WIDTH{1'b0}}       ),
                                         .fetch_in0_req_strb         ({(BUS_DATA_WIDTH/8){1'b0}}   ),
                                         .fetch_in0_req_opcode       (TOY_BUS_READ                 ),
                                         .fetch_in0_req_sideband     (10'b0                        ),
                                         .fetch_in0_ack_vld          (                             ),
                                         .fetch_in0_ack_rdy          (1'b0                         ),
                                         .fetch_in0_ack_data         (                             ),
                                         .fetch_in0_ack_sideband     (                             ),

                                         .lsu_in0_req_vld            (lsu_mem_req_vld            ),
                                         .lsu_in0_req_rdy            (lsu_mem_req_rdy            ),
                                         .lsu_in0_req_addr           (lsu_mem_req_addr           ),
                                         .lsu_in0_req_data           (lsu_mem_req_data           ),
                                         .lsu_in0_req_strb           (lsu_mem_req_strb           ),
                                         .lsu_in0_req_opcode         (lsu_mem_req_opcode         ),
                                         .lsu_in0_req_sideband       (lsu_mem_req_sideband       ),
                                         .lsu_in0_ack_vld            (lsu_mem_ack_vld            ),
                                         .lsu_in0_ack_rdy            (lsu_mem_ack_rdy            ),
                                         .lsu_in0_ack_data           (lsu_mem_ack_data           ),
                                         .lsu_in0_ack_sideband       (lsu_mem_ack_sideband       ),

                                         .itcm_out0_mem_en           (inst_mem_en          ),
                                         .itcm_out0_mem_addr         (inst_mem_addr        ),
                                         .itcm_out0_mem_rd_data      (inst_mem_rd_data     ),
                                         .itcm_out0_mem_wr_data      (inst_mem_wr_data     ),
                                         .itcm_out0_mem_wr_byte_en   (inst_mem_wr_byte_en  ),
                                         .itcm_out0_mem_wr_en        (inst_mem_wr_en       ),
                                         .itcm_out0_mem_req_sideband (inst_mem_req_sideband),
                                         .itcm_out0_mem_ack_sideband (inst_mem_ack_sideband),

                                         .dtcm_out0_mem_en           (dtcm_mem_en                ),
                                         .dtcm_out0_mem_addr         (dtcm_mem_addr              ),
                                         .dtcm_out0_mem_rd_data      (dtcm_mem_rd_data           ),
                                         .dtcm_out0_mem_wr_data      (dtcm_mem_wr_data           ),
                                         .dtcm_out0_mem_wr_byte_en   (dtcm_mem_wr_byte_en        ),
                                         .dtcm_out0_mem_wr_en        (dtcm_mem_wr_en             ),
                                         .dtcm_out0_mem_req_sideband (dtcm_mem_req_sideband      ),
                                         .dtcm_out0_mem_ack_sideband (dtcm_mem_ack_sideband      ),

                                         .eslv_out0_mem_en           (ext_mem_en                 ),
                                         .eslv_out0_mem_addr         (ext_mem_addr               ),
                                         .eslv_out0_mem_rd_data      (ext_mem_rd_data            ),
                                         .eslv_out0_mem_wr_data      (ext_mem_wr_data            ),
                                         .eslv_out0_mem_wr_byte_en   (ext_mem_wr_byte_en         ),
                                         .eslv_out0_mem_wr_en        (ext_mem_wr_en              ),
                                         .eslv_out0_mem_req_sideband (                           ),
                                         .eslv_out0_mem_ack_sideband ({FETCH_SB_WIDTH{1'b0}}     ));

endmodule