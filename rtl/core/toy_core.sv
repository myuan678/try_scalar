
module toy_core
    import toy_pack::*;
    (
     input  logic                      clk                     ,
     input  logic                      rst_n                   ,

     input  logic                           fetch_mem_ack_vld       ,
     output logic                           fetch_mem_ack_rdy       ,
     input  logic [FETCH_DATA_WIDTH-1:0]    fetch_mem_ack_data      ,
     input  logic [ROB_ENTRY_ID_WIDTH-1:0]  fetch_mem_ack_entry_id,
     output logic [ADDR_WIDTH-1:0]          fetch_mem_req_addr      ,
     output logic                           fetch_mem_req_vld       ,
     input  logic                           fetch_mem_req_rdy       ,
     output logic [ROB_ENTRY_ID_WIDTH-1:0]  fetch_mem_req_entry_id,


     output logic                      lsu_mem_req_vld         ,
     input  logic                      lsu_mem_req_rdy         ,
     output logic [ADDR_WIDTH-1:0]     lsu_mem_req_addr        ,
     output logic [DATA_WIDTH-1:0]     lsu_mem_req_data        ,
     output logic [DATA_WIDTH/8-1:0]   lsu_mem_req_strb        ,
     output logic                      lsu_mem_req_opcode      ,
     output logic [FETCH_SB_WIDTH-1:0] lsu_mem_req_sideband    ,
     input  logic [FETCH_SB_WIDTH-1:0] lsu_mem_ack_sideband    ,
     input  logic                      lsu_mem_ack_vld         ,
     output logic                      lsu_mem_ack_rdy         ,
     input  logic [DATA_WIDTH-1:0]     lsu_mem_ack_data        ,


     output logic                      custom_instruction_vld  ,
     input  logic                      custom_instruction_rdy  ,
     output logic [INST_WIDTH-1:0]     custom_instruction_pld  ,
     output logic [REG_WIDTH-1:0]      custom_rs1_val          ,
     output logic [REG_WIDTH-1:0]      custom_rs2_val          ,
     output logic [ADDR_WIDTH-1:0]     custom_pc               ,

     input  logic                      intr_meip               ,
     input  logic                      intr_msip

    );

    logic                      trap_pc_release_en           ;
    logic                      trap_pc_update_en            ;
    logic [ADDR_WIDTH-1:0]     trap_pc_val                  ;

    logic                      jb_pc_release_en             ;
    logic                      jb_pc_update_en              ;
    logic [ADDR_WIDTH-1:0]     jb_pc_val                    ;

    logic [INST_ALU_NUM-1:0]   v_jb_pc_release_en             ;
    logic [INST_ALU_NUM-1:0]   v_jb_pc_update_en              ;
    logic [ADDR_WIDTH-1:0]     v_jb_pc_val        [INST_ALU_NUM-1:0]  ;


    logic  [INST_READ_CHANNEL-1:0]  v_fetched_instruction_vld      ;
    logic  [INST_READ_CHANNEL-1:0]  v_fetched_instruction_rdy      ;
    logic  [INST_WIDTH_32-1:0]      v_fetched_instruction_pld  [INST_READ_CHANNEL-1:0]    ; 
    logic  [ADDR_WIDTH-1:0]         v_fetched_instruction_pc   [INST_READ_CHANNEL-1:0]    ;
    logic  [INST_IDX_WIDTH-1:0]     v_fetched_instruction_idx  [INST_READ_CHANNEL-1:0]    ;
    fe_bypass_pkg                   v_inst_fe_pld              [INST_READ_CHANNEL-1:0];

    logic                                      fetch_queue_rdy;
    logic                                      fetch_queue_vld;
    fetch_queue_pkg                            fetch_queue_pld     [FILTER_CHANNEL-1:0];
    logic           [FILTER_CHANNEL-1:0]       fetch_queue_en; 

    // alu ==================================================
    logic      [INST_ALU_NUM-1    :0]     v_alu_instruction_vld                          ;
    logic      [INST_ALU_NUM-1    :0]     v_alu_instruction_vld_rs                          ;
    logic      [INST_ALU_NUM-1    :0]     v_alu_instruction_rdy                          ;
    logic      [INST_ALU_NUM-1    :0]     v_alu_instruction_rdy_rs                          ;
    eu_pkg                                v_alu_instruction_pld   [INST_ALU_NUM-1    :0] ;
    eu_pkg                                v_alu_instruction_pld_rs   [INST_ALU_NUM-1    :0] ;
    logic      [PHY_REG_ID_WIDTH-1:0]     v_alu_reg_index         [INST_ALU_NUM-1    :0] ;
    logic      [INST_ALU_NUM-1    :0]     v_alu_reg_wr_en                                ;
    logic      [REG_WIDTH-1       :0]     v_alu_reg_val           [INST_ALU_NUM-1    :0] ;
    logic      [INST_IDX_WIDTH-1  :0]     v_alu_reg_inst_idx      [INST_ALU_NUM-1    :0] ;
    logic      [INST_ALU_NUM-1    :0]     v_alu_inst_commit_en                           ;
    commit_pkg                            v_alu_commit_pld        [INST_ALU_NUM-1    :0] ;

    // lsu ==================================================
    logic      [3                    :0]     v_lsu_instruction_vld           ;
    logic      [3                    :0]     v_lsu_instruction_rdy           ;
    lsu_pkg                                  v_lsu_pld                 [3:0]   ;
    logic      [1                    :0]     v_stq_commit_en                 ;
    commit_pkg                               v_stq_commit_pld          [1:0]   ;
    logic      [3                    :0]     v_st_ack_commit_en              ;
    logic      [3                    :0]     v_st_ack_commit_cancel_en       ;
    logic      [$clog2(STU_DEPTH)-1  :0]     v_st_ack_commit_entry     [3:0]   ;
    logic      [2                    :0]     v_ldq_commit_en                 ;
    commit_pkg                               v_ldq_commit_pld          [2:0]   ;
    logic      [2                    :0]     v_lsu_fp_reg_wr_en              ;
    logic      [PHY_REG_ID_WIDTH-1   :0]     v_lsu_reg_index           [2:0]   ;
    logic      [2                    :0]     v_lsu_reg_wr_en                 ;
    logic      [REG_WIDTH-1          :0]     v_lsu_reg_val             [2:0]   ;
    
    // float ==================================================
    logic                      float_instruction_vld        ;
    logic                      float_instruction_rdy        ;
    eu_pkg                     float_instruction_pld        ;
    commit_pkg                 fp_commit_pld                ;

    logic [PHY_REG_ID_WIDTH-1:0]float_reg_index             ;
    logic                       float_reg_wr_en              ;
    logic [REG_WIDTH-1:0]       float_reg_val                ;
    logic                       float_fp_reg_wr_en           ;
    logic [INST_IDX_WIDTH-1:0]  float_reg_inst_idx           ;
    logic                       float_inst_commit_en         ;

    // mext ==================================================
    logic                            mext_instruction_vld          ;
    logic                            mext_instruction_rdy          ;
    logic      [INST_WIDTH-1:0]      mext_instruction_pld          ;
    logic      [INST_IDX_WIDTH-1:0]  mext_instruction_idx          ;
    logic      [PHY_REG_ID_WIDTH-1:0]mext_inst_rd_idx             ;
    logic                            mext_inst_rd_en               ;
    logic      [REG_WIDTH-1:0]       mext_rs1_val                  ;
    logic      [REG_WIDTH-1:0]       mext_rs2_val                  ;
    logic      [31:0]                mext_inst_imm                 ;
    logic      [ADDR_WIDTH-1:0]      mext_pc                       ;
    logic      [4:0]                 mext_arch_reg_index           ;
    commit_pkg                       mext_commit_pld               ;
    logic                            mext_c_ext                    ;
    logic      [PHY_REG_ID_WIDTH-1:0]mext_reg_index               ;
    logic                            mext_reg_wr_en                ;
    logic      [REG_WIDTH-1:0]       mext_reg_val                  ;
    logic      [INST_IDX_WIDTH-1:0]  mext_reg_inst_idx             ;
    logic                            mext_inst_commit_en           ;

    // csr ===================================================
    logic                            csr_instruction_vld           ;
    logic                            csr_instruction_rdy           ;
    logic      [INST_WIDTH-1:0]      csr_instruction_pld           ;
    logic      [INST_IDX_WIDTH-1:0]  csr_instruction_idx           ;
    logic                            csr_instruction_is_intr       ;
    logic      [PHY_REG_ID_WIDTH-1:0]csr_inst_rd_idx              ;
    logic                            csr_inst_rd_en                ;
    logic      [REG_WIDTH-1:0]       csr_rs1_val                   ;
    logic      [REG_WIDTH-1:0]       csr_rs2_val                   ;
    logic      [ADDR_WIDTH-1:0]      csr_pc                        ;
    logic      [4:0]                 csr_arch_reg_index            ;
    logic      [31:0]                csr_inst_imm                  ;
    commit_pkg                       csr_commit_pld                ;
    logic                            csr_c_ext                     ;

    logic [PHY_REG_ID_WIDTH-1:0]csr_reg_index                ;
    logic                       csr_reg_wr_en                 ;
    logic [REG_WIDTH-1:0]       csr_reg_val                   ;
    logic [INST_IDX_WIDTH-1:0]  csr_reg_inst_idx              ;
    logic                       csr_inst_commit_en            ;

    logic      [63:0]                       csr_INSTRET                   ;
    logic      [31:0]                       csr_FCSR                      ;
    logic      [4:0]                        csr_FFLAGS                    ;
    logic                                   csr_FFLAGS_en                 ;
    logic                                   csr_intr_instruction_vld      ;
    logic                                   csr_intr_instruction_rdy      ;
    // commit
    logic                                   cancel_en                   ;
    logic                                   cancel_edge_en              ;
    logic      [ADDR_WIDTH-1         :0]    fetch_update_pc             ;
    logic      [COMMIT_REL_CHANNEL-1 :0]    v_rf_commit_en              ;
    logic                                   commit_credit_rel_en        ;
    logic      [2                  :0]      commit_credit_rel_num       ;
    commit_pkg                              v_rf_commit_pld          [COMMIT_REL_CHANNEL-1:0];
    logic      [COMMIT_REL_CHANNEL-1 :0]    v_commit_error_en ;
    be_pkg                                  v_bp_commit_pld          [COMMIT_REL_CHANNEL-1:0];
    logic      [7                   :0]     FCSR_backup;

    toy_bpu u_bpu (
                   .clk                (clk                   ),
                   .rst_n              (rst_n                 ),
                   .icache_req_vld     (fetch_mem_req_vld     ),
                   .icache_req_rdy     (fetch_mem_req_rdy     ),
                   .icache_req_entry_id(fetch_mem_req_entry_id),
                   .icache_req_addr    (fetch_mem_req_addr    ),
                   .icache_ack_rdy     (fetch_mem_ack_rdy     ),
                   .icache_ack_vld     (fetch_mem_ack_vld     ),
                   .icache_ack_pld     (fetch_mem_ack_data    ),
                   .icache_ack_entry_id(fetch_mem_ack_entry_id),
                   .fetch_queue_rdy    (fetch_queue_rdy       ),
                   .fetch_queue_vld    (fetch_queue_vld       ),
                   .fetch_queue_pld    (fetch_queue_pld       ),
                   .fetch_queue_en     (fetch_queue_en        ),
                   .be_commit_vld      (v_rf_commit_en        ),
                   .be_commit_pld      (v_bp_commit_pld       ),
                   .be_cancel_en       (cancel_en             ),
                   .be_cancel_edge     (cancel_edge_en        ),
                   .be_commit_error_en (v_commit_error_en     ),
                   .be_cancel_pld      (v_bp_commit_pld       )
                  );

    toy_fetch_queue2 #(
        .DEPTH(FETCH_QUEUE_DEPTH    )
    )u_fetch(
                            .clk       (clk                      ),
                            .rst_n     (rst_n                    ),
                            .cancel_en (cancel_edge_en           ),
                            .filter_rdy(fetch_queue_rdy          ),
                            .filter_vld(fetch_queue_vld          ),
                            .filter_pld(fetch_queue_pld          ),
                            .filter_en (fetch_queue_en           ),
                            .v_ack_vld (v_fetched_instruction_vld),
                            .v_ack_rdy (v_fetched_instruction_rdy),
                            .v_ack_pc  (v_fetched_instruction_pc ),
                            .v_ack_pld (v_fetched_instruction_pld),
                            .v_ack_idx (v_fetched_instruction_idx),
                            .v_fe_pld  (v_inst_fe_pld            ),
                            .commit_credit_rel_en(commit_credit_rel_en),
                            .commit_credit_rel_num(commit_credit_rel_num)
                           );


    toy_dispatch u_dispatch(
                            .clk                        (clk                        ),
                            .rst_n                      (rst_n                      ),
                            // fetch =================================================
                            .v_fetched_instruction_vld  (v_fetched_instruction_vld  ),
                            .v_fetched_instruction_rdy  (v_fetched_instruction_rdy  ),
                            .v_fetched_instruction_pld  (v_fetched_instruction_pld  ), 
                            .v_fetched_instruction_pc   (v_fetched_instruction_pc   ),
                            .v_fetched_instruction_idx  (v_fetched_instruction_idx  ),
                            // cancel ================================================
                            .cancel_edge_en             (cancel_edge_en             ),
                            .v_commit_en                (v_rf_commit_en             ),
                            .v_commit_pld               (v_rf_commit_pld            ),
                            // lsu ===================================================
                            .v_lsu_instruction_vld      (v_lsu_instruction_vld      ),
                            .v_lsu_instruction_rdy      (v_lsu_instruction_rdy      ),
                            .v_lsu_pld                  (v_lsu_pld                  ),
                            .v_lsu_reg_index            (v_lsu_reg_index            ),
                            .v_lsu_reg_wr_en            (v_lsu_reg_wr_en            ),
                            .v_lsu_reg_val              (v_lsu_reg_val              ),
                            .v_lsu_fp_reg_wr_en         (v_lsu_fp_reg_wr_en         ),
                            // alu ===================================================
                            .v_alu_instruction_vld      (v_alu_instruction_vld      ),
                            .v_alu_instruction_rdy      (v_alu_instruction_rdy      ),
                            .v_alu_instruction_pld      (v_alu_instruction_pld      ),
                            .v_alu_reg_index            (v_alu_reg_index            ),
                            .v_alu_reg_wr_en            (v_alu_reg_wr_en            ),
                            .v_alu_reg_val              (v_alu_reg_val              ),
                            .v_alu_reg_inst_idx         (v_alu_reg_inst_idx         ),
                            .v_alu_inst_commit_en       (v_alu_inst_commit_en       ),
                            // mext ==================================================
                            .mext_instruction_vld       (mext_instruction_vld       ),
                            .mext_instruction_rdy       (mext_instruction_rdy       ),
                            .mext_instruction_pld       (mext_instruction_pld       ),
                            .mext_instruction_idx       (mext_instruction_idx       ),
                            .mext_inst_rd_idx           (mext_inst_rd_idx           ),
                            .mext_inst_rd_en            (mext_inst_rd_en            ),
                            .mext_c_ext                 (mext_c_ext                 ),
                            .mext_arch_reg_index        (mext_arch_reg_index        ),
                            .mext_inst_imm              (mext_inst_imm              ),
                            .mext_pc                    (mext_pc                    ),
                            .mext_rs1_val               (mext_rs1_val               ),
                            .mext_rs2_val               (mext_rs2_val               ),
                            .mext_reg_index             (mext_reg_index             ),
                            .mext_reg_wr_en             (mext_reg_wr_en             ),
                            .mext_reg_val               (mext_reg_val               ),
                            .mext_reg_inst_idx          (mext_reg_inst_idx          ),
                            .mext_inst_commit_en        (mext_inst_commit_en        ),
                            // float =================================================     
                            .float_instruction_vld      (float_instruction_vld      ),        
                            .float_instruction_rdy      (float_instruction_rdy      ),        
                            .float_instruction_pld      (float_instruction_pld      ),                      
                            .float_reg_index            (float_reg_index            ),        
                            .float_reg_wr_en            (float_reg_wr_en            ),        
                            .float_reg_val              (float_reg_val              ),            
                            .float_fp_reg_wr_en         (float_fp_reg_wr_en         ),            
                            .float_reg_inst_idx         (float_reg_inst_idx         ),        
                            .float_inst_commit_en       (float_inst_commit_en       ),        
                            // csr ===================================================
                            .csr_instruction_vld        (csr_instruction_vld        ),
                            .csr_instruction_rdy        (csr_instruction_rdy        ),
                            .csr_instruction_pld        (csr_instruction_pld        ),
                            .csr_instruction_idx        (csr_instruction_idx        ),
                            .csr_instruction_is_intr    (csr_instruction_is_intr    ),
                            .csr_intr_instruction_vld   (csr_intr_instruction_vld   ),
                            .csr_intr_instruction_rdy   (csr_intr_instruction_rdy   ),
                            .csr_inst_rd_idx            (csr_inst_rd_idx            ),
                            .csr_inst_rd_en             (csr_inst_rd_en             ),
                            .csr_c_ext                  (csr_c_ext                  ),
                            .csr_arch_reg_index         (csr_arch_reg_index         ),
                            .csr_inst_imm               (csr_inst_imm               ),
                            .csr_rs1_val                (csr_rs1_val                ),
                            .csr_rs2_val                (csr_rs2_val                ),
                            .csr_reg_index              (csr_reg_index              ),
                            .csr_reg_wr_en              (csr_reg_wr_en              ),
                            .csr_reg_val                (csr_reg_val                ),
                            .csr_reg_inst_idx           (csr_reg_inst_idx           ),
                            .csr_inst_commit_en         (csr_inst_commit_en         ),
                            .csr_pc                     (csr_pc                     ),
                            // custom ================================================
                            .custom_instruction_vld     (custom_instruction_vld     ),       
                            .custom_instruction_rdy     (custom_instruction_rdy     ),       
                            .custom_instruction_pld     (custom_instruction_pld     ),       
                            .custom_rs1_val             (custom_rs1_val             ),       
                            .custom_rs2_val             (custom_rs2_val             ),       
                            .custom_pc                  (custom_pc                  ));
    generate
        for (genvar i=0;i<INST_ALU_NUM;i=i+1)begin : ALU_INST
            // reg_slice_forward #(
            //     .PLD_TYPE   (eu_pkg                     )
            // )u_alu_rs(
            //     .clk        (clk                        ),
            //     .rst_n      (rst_n                      ),
            //     .s_vld      (v_alu_instruction_vld[i]   ),
            //     .s_rdy      (v_alu_instruction_rdy[i]   ),
            //     .s_pld      (v_alu_instruction_pld[i]   ),
            //     .m_vld      (v_alu_instruction_vld_rs[i]),
            //     .m_rdy      (v_alu_instruction_rdy_rs[i]),
            //     .m_pld      (v_alu_instruction_pld_rs[i])
            // );

            toy_alu u_alu(
                          .clk                        (clk                             ),
                          .rst_n                      (rst_n                           ),
                        //   .instruction_vld            (v_alu_instruction_vld_rs[i]        ),
                        //   .instruction_rdy            (v_alu_instruction_rdy_rs[i]        ),
                        //   .instruction_pld            (v_alu_instruction_pld_rs[i]        ),
                          .instruction_vld            (v_alu_instruction_vld[i]        ),
                          .instruction_rdy            (v_alu_instruction_rdy[i]        ),
                          .instruction_pld            (v_alu_instruction_pld[i]        ),
                          .reg_inst_idx               (v_alu_reg_inst_idx[i]           ),
                          .reg_index                  (v_alu_reg_index[i]              ),
                          .reg_wr_en                  (v_alu_reg_wr_en[i]              ),
                          .reg_data                   (v_alu_reg_val[i]                ),
                          .inst_commit_en             (v_alu_inst_commit_en[i]         ),
                          .alu_commit_pld             (v_alu_commit_pld[i]             ),
                          .pc_release_en              (v_jb_pc_release_en[i]           ),
                          .pc_update_en               (v_jb_pc_update_en[i]            ),
                          .pc_val                     (v_jb_pc_val[i]                  ));
        end
    endgenerate

    assign jb_pc_release_en = | v_jb_pc_release_en            ;         
    assign jb_pc_update_en  = | v_jb_pc_update_en             ;
    assign jb_pc_val        =  v_jb_pc_update_en[0] ? v_jb_pc_val[0] :
                        v_jb_pc_update_en[1] ? v_jb_pc_val[1] :
                        v_jb_pc_update_en[2] ? v_jb_pc_val[2] : 
                                               v_jb_pc_val[3] ;


    toy_lsu u_toy_lsu(
                      .clk                        (clk                        ),
                      .rst_n                      (rst_n                      ),
                      .v_instruction_vld          (v_lsu_instruction_vld      ),
                      .v_instruction_rdy          (v_lsu_instruction_rdy      ),
                      .v_lsu_pld                  (v_lsu_pld                  ),
                      .reg_index                  (v_lsu_reg_index            ),
                      .reg_wr_en                  (v_lsu_reg_wr_en            ),
                      .reg_val                    (v_lsu_reg_val              ),
                      .fp_reg_wr_en               (v_lsu_fp_reg_wr_en         ),
                      .v_stq_commit_en            (v_stq_commit_en            ),
                      .v_stq_commit_pld           (v_stq_commit_pld           ),      
                      .v_st_ack_commit_en         (v_st_ack_commit_en         ),         
                      .v_st_ack_commit_cancel_en  (v_st_ack_commit_cancel_en  ),      
                      .v_st_ack_commit_entry      (v_st_ack_commit_entry      ),  
                      .v_ldq_commit_en            (v_ldq_commit_en            ),        
                      .v_ldq_commit_pld           (v_ldq_commit_pld           ),   
                      .cancel_en                  (cancel_en                  ),
                      .cancel_edge_en             (cancel_edge_en             ),   
                      .mem_req_vld                (lsu_mem_req_vld            ),
                      .mem_req_rdy                (lsu_mem_req_rdy            ),
                      .mem_req_addr               (lsu_mem_req_addr           ),
                      .mem_req_data               (lsu_mem_req_data           ),
                      .mem_req_strb               (lsu_mem_req_strb           ),
                      .mem_req_opcode             (lsu_mem_req_opcode         ),
                      .mem_req_sideband           (lsu_mem_req_sideband       ),
                      .mem_ack_sideband           (lsu_mem_ack_sideband       ),
                      .mem_ack_vld                (lsu_mem_ack_vld            ),
                      .mem_ack_rdy                (lsu_mem_ack_rdy            ),
                      .mem_ack_data               (lsu_mem_ack_data           ));


    toy_float_wrapper u_float(
                      .clk                        (clk                        ),
                      .rst_n                      (rst_n                      ),
                      .instruction_vld            (float_instruction_vld      ),
                      .instruction_rdy            (float_instruction_rdy      ),
                      .instruction_pld            (float_instruction_pld      ),
                      .csr_FCSR                   (csr_FCSR                   ),
                      .csr_FFLAGS                 (csr_FFLAGS                 ),
                      .csr_FFLAGS_en              (csr_FFLAGS_en              ),
                      .fp_commit_pld              (fp_commit_pld              ),
                      .reg_index                  (float_reg_index            ),
                      .reg_wr_en                  (float_reg_wr_en            ),
                      .reg_val                    (float_reg_val              ),
                      .fp_reg_wr_en               (float_fp_reg_wr_en         ),
                      .reg_inst_idx               (float_reg_inst_idx         ),
                      .inst_commit_en             (float_inst_commit_en       ));


    toy_mext u_mext(
                    .clk                        (clk                        ),
                    .rst_n                      (rst_n                      ),
                    .instruction_vld            (mext_instruction_vld       ),
                    .instruction_rdy            (mext_instruction_rdy       ),
                    .instruction_pld            (mext_instruction_pld       ),
                    .instruction_idx            (mext_instruction_idx       ),
                    .inst_rd_idx                (mext_inst_rd_idx           ),
                    .inst_rd_en                 (mext_inst_rd_en            ),
                    .mext_c_ext                 (mext_c_ext                 ),
                    .arch_reg_index             (mext_arch_reg_index        ),
                    .rs1_val                    (mext_rs1_val               ),
                    .rs2_val                    (mext_rs2_val               ),
                    .cancel_en                  (cancel_en                  ),
                    .inst_pc                    (mext_pc                    ),
                    .mext_commit_pld            (mext_commit_pld            ),
                    .reg_index                  (mext_reg_index             ),
                    .reg_wr_en                  (mext_reg_wr_en             ),
                    .reg_val                    (mext_reg_val               ),
                    .reg_inst_idx               (mext_reg_inst_idx          ),
                    .inst_commit_en             (mext_inst_commit_en        ));



    toy_csr u_csr(
                  .clk                        (clk                        ),
                  .rst_n                      (rst_n                      ),
                  .intr_instruction_vld       (csr_intr_instruction_vld   ),
                  .intr_instruction_rdy       (csr_intr_instruction_rdy   ),

                  .instruction_vld            (csr_instruction_vld        ),
                  .instruction_rdy            (csr_instruction_rdy        ),
                  .instruction_pld            (csr_instruction_pld        ),
                  .instruction_idx            (csr_instruction_idx        ),
                  .instruction_is_intr        (csr_instruction_is_intr    ),
                  .inst_rd_idx                (csr_inst_rd_idx            ),
                  .inst_rd_en                 (csr_inst_rd_en             ),
                  .csr_c_ext                  (csr_c_ext                  ),
                  .arch_reg_index             (csr_arch_reg_index         ),
                  .rs1_val                    (csr_rs1_val                ),
                  .rs2_val                    (csr_rs2_val                ),
                  .pc                         (csr_pc                     ),
                  .reg_index                  (csr_reg_index              ),
                  .reg_wr_en                  (csr_reg_wr_en              ),
                  .reg_val                    (csr_reg_val                ),
                  .reg_inst_idx               (csr_reg_inst_idx           ),
                  .inst_commit_en             (csr_inst_commit_en         ),
                  .csr_commit_pld             (csr_commit_pld             ),
                  .csr_INSTRET                (csr_INSTRET                ),
                  .cancel_edge_en             (cancel_edge_en             ),
                  .FCSR_backup                (FCSR_backup                ),
                  .csr_FCSR                   (csr_FCSR                   ),
                  .csr_FFLAGS                 (csr_FFLAGS                 ),
                  .csr_FFLAGS_en              (csr_FFLAGS_en              ),
                  .pc_release_en              (trap_pc_release_en         ),
                  .pc_update_en               (trap_pc_update_en          ),
                  .pc_val                     (trap_pc_val                ),
                  .intr_meip                  (intr_meip                  ),
                  .intr_msip                  (intr_msip                  ));

    toy_commit u_toy_commit(

                            .clk                        (clk                          ),
                            .rst_n                      (rst_n                        ),
                            .v_alu_commit_en            (v_alu_inst_commit_en         ),
                            .v_alu_commit_pld           (v_alu_commit_pld             ),
                            .v_stq_commit_en            (v_stq_commit_en              ),
                            .v_stq_commit_pld           (v_stq_commit_pld             ),
                            .v_st_ack_commit_en         (v_st_ack_commit_en           ),
                            .v_st_ack_commit_entry      (v_st_ack_commit_entry        ),
                            .v_ldq_commit_en            (v_ldq_commit_en              ),
                            .v_ldq_commit_pld           (v_ldq_commit_pld             ),
                            .fp_commit_en               (float_inst_commit_en         ),
                            .fp_commit_pld              (fp_commit_pld                ),
                            .mext_commit_en             (mext_inst_commit_en          ),
                            .mext_commit_pld            (mext_commit_pld              ),
                            .csr_commit_en              (csr_inst_commit_en           ),
                            .csr_commit_pld             (csr_commit_pld               ),
                            .v_instruction_vld          (v_fetched_instruction_vld    ),
                            .v_instruction_rdy          (v_fetched_instruction_rdy    ),
                            // .v_instruction_pc           (v_fetched_instruction_pc     ),
                            .v_instruction_idx          (v_fetched_instruction_idx    ),
                            .v_inst_fe_pld              (v_inst_fe_pld                ),
                            .cancel_en                  (cancel_en                    ),
                            .cancel_edge_en             (cancel_edge_en               ),
                            .FCSR_backup                (FCSR_backup                  ),
                            // .fetch_update_pc            (fetch_update_pc              ),
                            .v_rf_commit_en             (v_rf_commit_en               ), //commit en
                            .v_rf_commit_pld            (v_rf_commit_pld              ),
                            .v_commit_error_en          (v_commit_error_en            ), //todo for tao
                            .v_bp_commit_pld            (v_bp_commit_pld              ), //todo for tao
                            .csr_INSTRET                (csr_INSTRET                  ),
                            .commit_credit_rel_en       (commit_credit_rel_en         ),
                            .commit_credit_rel_num      (commit_credit_rel_num        )

                           );





endmodule