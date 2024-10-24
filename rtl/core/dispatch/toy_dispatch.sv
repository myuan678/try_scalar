

module toy_dispatch 
    import toy_pack::*;
(
    input  logic                                clk                                 ,
    input  logic                                rst_n                               ,

    input  logic [INST_READ_CHANNEL-1   :0]    v_fetched_instruction_vld            ,
    output logic [INST_READ_CHANNEL-1   :0]    v_fetched_instruction_rdy            ,
    input  logic [INST_WIDTH-1          :0]    v_fetched_instruction_pld [INST_READ_CHANNEL-1:0]     , 
    input  logic [ADDR_WIDTH-1          :0]    v_fetched_instruction_pc  [INST_READ_CHANNEL-1:0]     ,
    input  logic [INST_IDX_WIDTH-1      :0]    v_fetched_instruction_idx [INST_READ_CHANNEL-1:0]     ,    
    // commit ======================================================================
    input  logic                               cancel_edge_en                       ,  
    input  logic [COMMIT_REL_CHANNEL-1  :0]    v_commit_en                          ,
    input  commit_pkg                          v_commit_pld [COMMIT_REL_CHANNEL-1:0], 

    // LSU =========================================================================
    output logic [3                     :0]     v_lsu_instruction_vld       ,
    input  logic [3                     :0]     v_lsu_instruction_rdy       ,
    output lsu_pkg                              v_lsu_pld       [3:0]       ,
    input  logic [PHY_REG_ID_WIDTH-1    :0]     v_lsu_reg_index     [2:0]   ,
    input  logic [2:0]                          v_lsu_reg_wr_en             ,
    input  logic [2:0]                          v_lsu_fp_reg_wr_en          , 
    input  logic [REG_WIDTH-1           :0]     v_lsu_reg_val       [2:0]   ,

    // ALU =========================================================================
    output logic [INST_ALU_NUM-1        :0]     v_alu_instruction_vld                               ,
    input  logic [INST_ALU_NUM-1        :0]     v_alu_instruction_rdy                               ,
    output eu_pkg                               v_alu_instruction_pld   [INST_ALU_NUM-1    :0]      ,
    input  logic [PHY_REG_ID_WIDTH-1    :0]     v_alu_reg_index         [INST_ALU_NUM-1    :0]      ,
    input  logic [INST_ALU_NUM-1        :0]     v_alu_reg_wr_en                                     ,
    input  logic [REG_WIDTH-1           :0]     v_alu_reg_val           [INST_ALU_NUM-1    :0]      ,
    input  logic [INST_IDX_WIDTH-1      :0]     v_alu_reg_inst_idx      [INST_ALU_NUM-1    :0]      ,
    input  logic [INST_ALU_NUM-1        :0]     v_alu_inst_commit_en                                ,

    // MEXT =========================================================================
    output logic                                mext_instruction_vld        ,
    input  logic                                mext_instruction_rdy        ,
    output logic [INST_WIDTH-1          :0]     mext_instruction_pld        ,
    output logic [INST_IDX_WIDTH-1      :0]     mext_instruction_idx        ,
    output logic [PHY_REG_ID_WIDTH-1    :0]     mext_inst_rd_idx            ,
    output logic                                mext_inst_rd_en             , 
    output logic                                mext_c_ext                  , 
    output logic [4                     :0]     mext_arch_reg_index         ,
    output logic [31                    :0]     mext_inst_imm               ,
    output logic [ADDR_WIDTH-1          :0]     mext_pc                     ,
    output logic [REG_WIDTH-1           :0]     mext_rs1_val                ,
    output logic [REG_WIDTH-1           :0]     mext_rs2_val                ,

    input  logic [PHY_REG_ID_WIDTH-1    :0]     mext_reg_index              ,
    input  logic                                mext_reg_wr_en              ,
    input  logic [REG_WIDTH-1           :0]     mext_reg_val                ,
    input  logic [INST_IDX_WIDTH-1      :0]     mext_reg_inst_idx           ,
    input                                       mext_inst_commit_en         ,
    
    // FLOAT ========================================================================
    output logic                                float_instruction_vld        ,
    input  logic                                float_instruction_rdy        ,
    output eu_pkg                               float_instruction_pld        ,

    input  logic [PHY_REG_ID_WIDTH-1    :0]     float_reg_index              ,
    input  logic                                float_reg_wr_en              ,
    input  logic [REG_WIDTH-1           :0]     float_reg_val                ,
    input  logic                                float_fp_reg_wr_en           ,
    input  logic [INST_IDX_WIDTH-1      :0]     float_reg_inst_idx           ,
    input                                       float_inst_commit_en         ,

    // Custom 0 ====================================================================
    output logic                                custom_instruction_vld      ,
    input  logic                                custom_instruction_rdy      ,
    output logic [INST_WIDTH-1          :0]     custom_instruction_pld      ,
    output logic [REG_WIDTH-1           :0]     custom_rs1_val              ,
    output logic [REG_WIDTH-1           :0]     custom_rs2_val              ,
    output logic [ADDR_WIDTH-1          :0]     custom_pc                   ,


    // CSR =========================================================================
    output logic                                csr_instruction_vld         ,
    input  logic                                csr_instruction_rdy         ,
    output logic [INST_WIDTH-1          :0]     csr_instruction_pld         ,
    output logic [INST_IDX_WIDTH-1      :0]     csr_instruction_idx         ,
    output logic                                csr_instruction_is_intr     ,
    output logic [PHY_REG_ID_WIDTH-1    :0]     csr_inst_rd_idx             ,
    output logic                                csr_inst_rd_en              , 
    output logic                                csr_c_ext                   , 
    output logic [31                    :0]     csr_inst_imm                ,
    output logic [4                     :0]     csr_arch_reg_index          ,
    output logic [ADDR_WIDTH-1          :0]     csr_pc                      ,
    output logic [REG_WIDTH-1           :0]     csr_rs1_val                 ,
    output logic [REG_WIDTH-1           :0]     csr_rs2_val                 ,

    input  logic [PHY_REG_ID_WIDTH-1    :0]     csr_reg_index               ,
    input  logic                                csr_reg_wr_en               ,
    input  logic [REG_WIDTH-1           :0]     csr_reg_val                 ,
    input  logic [INST_IDX_WIDTH-1      :0]     csr_reg_inst_idx            ,
    input                                       csr_inst_commit_en          ,


    input  logic                                csr_intr_instruction_vld    ,
    output logic                                csr_intr_instruction_rdy     
);

    //##############################################
    // logic  
    //##############################################
    logic                               csr_lock                ;

    logic [31                   :0]     wr_ch0_en_bitmap        ;
    logic [31                   :0]     wr_ch1_en_bitmap        ;
    logic [31                   :0]     wr_ch2_en_bitmap        ;
    logic [31                   :0]     wr_ch3_en_bitmap        ;
    logic [31                   :0]     wr_ch4_en_bitmap        ;
    logic [31                   :0]     wr_ch5_en_bitmap        ;
    logic [31                   :0]     wr_ch6_en_bitmap        ;
    logic [31                   :0]     wr_ch7_en_bitmap        ;
    logic [31                   :0]     wr_ch0_en_fp_bitmap     ;
    logic [31                   :0]     wr_ch1_en_fp_bitmap     ;

    logic [INST_DECODE_NUM-1    :0]     v_goto_lsu              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_ldu              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_stu              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_alu              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_err              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_mext             ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_float            ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_csr              ;
    logic [INST_DECODE_NUM-1    :0]     v_goto_custom           ;

    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_vld          ;
    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_rdy          ;
    logic [INST_DECODE_NUM-1    :0]     v_eu_vld                ;
    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_rd_en        ;
    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_fp_rd_en     ;
    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_is_intr      ;
    logic [INST_DECODE_NUM-1    :0]     v_dec_inst_c_ext        ;

    logic [31                   :0]     register_lock           ;
    logic [31                   :0]     register_lock_release   ;
    logic [31                   :0]     fp_register_lock        ;
    logic [31                   :0]     fp_register_lock_release;

    logic [INST_DECODE_NUM-1    :0]     v_use_rs1_en            ;
    logic [INST_DECODE_NUM-1    :0]     v_use_rs2_en            ;
    logic [INST_DECODE_NUM-1    :0]     v_use_rs1_fp_en         ;    
    logic [INST_DECODE_NUM-1    :0]     v_use_rs2_fp_en         ;    
    logic [INST_DECODE_NUM-1    :0]     v_use_rs3_fp_en         ;    
    
    logic [EU_NUM-1             :0]     v_int_wr_en             ;
    logic [EU_NUM-1             :0]     v_fp_wr_en              ;
    logic [INST_DECODE_NUM-1    :0]     v_int_pre_allocate_vld  ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_pre_allocate_vld   ;
    
    logic [INST_DECODE_NUM-1    :0]     v_int_reg_rs1_rdy       ;
    logic [INST_DECODE_NUM-1    :0]     v_int_reg_rs2_rdy       ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_reg_rs1_rdy        ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_reg_rs2_rdy        ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_reg_rs3_rdy        ;

    logic [INST_DECODE_NUM-1    :0]     v_int_pre_allocate_rdy  ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_pre_allocate_rdy   ;
    logic [INST_DECODE_NUM-1    :0]     v_int_pre_allocate_zero ;
    logic [INST_READ_CHANNEL-1  :0]     v_csr_intr_instruction_rdy;
    logic [INST_DECODE_NUM-1    :0]     v_int_reg_rd_en         ;
    logic [INST_DECODE_NUM-1    :0]     v_fp_reg_rd_en          ;

    logic [PHY_REG_ID_WIDTH-1   :0]     v_int_phy_reg_rd_index[INST_DECODE_NUM-1  :0] ;
    logic [PHY_REG_ID_WIDTH-1   :0]     v_fp_phy_reg_rd_index [INST_DECODE_NUM-1  :0] ;
    logic [PHY_REG_ID_WIDTH-1   :0]     v_int_pre_allocate_id [INST_DECODE_NUM-1  :0] ;
    logic [PHY_REG_ID_WIDTH-1   :0]     v_fp_pre_allocate_id  [INST_DECODE_NUM-1  :0] ;
    logic [PHY_REG_ID_WIDTH-1   :0]     v_wr_reg_index        [EU_NUM-1           :0] ;
    logic [REG_WIDTH-1          :0]     v_wr_reg_data         [EU_NUM-1           :0] ;

    logic [INST_WIDTH-1         :0]     v_dec_inst_pld      [INST_DECODE_NUM-1    :0] ;
    logic [INST_IDX_WIDTH-1     :0]     v_dec_inst_id       [INST_DECODE_NUM-1    :0] ;
    logic [4                    :0]     v_dec_inst_rd       [INST_DECODE_NUM-1    :0] ;
    logic [ADDR_WIDTH-1         :0]     v_dec_inst_pc       [INST_DECODE_NUM-1    :0] ;
    logic [4                    :0]     v_dec_inst_rs1      [INST_DECODE_NUM-1    :0] ;
    logic [4                    :0]     v_dec_inst_rs2      [INST_DECODE_NUM-1    :0] ;
    logic [4                    :0]     v_dec_inst_rs3      [INST_DECODE_NUM-1    :0] ;
    logic [31                   :0]     v_dec_inst_imm      [INST_DECODE_NUM-1    :0] ;

    logic [REG_WIDTH-1          :0]     v_float_fp_rs1_val  [INST_DECODE_NUM-1   :0]  ;
    logic [REG_WIDTH-1          :0]     v_float_fp_rs2_val  [INST_DECODE_NUM-1   :0]  ;
    logic [REG_WIDTH-1          :0]     v_float_fp_rs3_val  [INST_DECODE_NUM-1   :0]  ;
    logic [REG_WIDTH-1          :0]     v_lsu_fp_rs2_val    [INST_DECODE_NUM-1   :0]  ;
    logic [REG_WIDTH-1          :0]     v_lsu_rs2_val_temp  [INST_DECODE_NUM-1   :0]  ;


    logic [31                   :0]     v_reg_rs1_val      [INST_DECODE_NUM-1  :0]  ;
    logic [31                   :0]     v_reg_rs2_val      [INST_DECODE_NUM-1  :0]  ;
    logic [31                   :0]     v_fp_reg_rs1_val   [INST_DECODE_NUM-1  :0]  ;
    logic [31                   :0]     v_fp_reg_rs2_val   [INST_DECODE_NUM-1  :0]  ;
    logic [31                   :0]     v_fp_reg_rs3_val   [INST_DECODE_NUM-1  :0]  ;

    logic [PHY_REG_ID_WIDTH-1   :0]     v_int_rd_phy_id    [INST_DECODE_NUM-1  :0]  ;
    logic [PHY_REG_ID_WIDTH-1   :0]     v_fp_rd_phy_id     [INST_DECODE_NUM-1  :0]  ;
    logic [INST_READ_CHANNEL-1  :0]     v_dec_buffer_vld                            ;
    logic [INST_READ_CHANNEL-1  :0]     v_dec_buffer_rdy                            ;


    //##############################################
    // package 
    //##############################################
    eu_pkg                              mext_pld                       ;
    eu_pkg                              csr_pld                        ;
    eu_pkg                              custom_pld                     ;        
    eu_pkg                              v_alu_pld [INST_ALU_NUM-1:0]   ;
    decode_pkg                          v_dec_buffer_pld     [INST_READ_CHANNEL-1   :0];
    decode_pkg                          v_dec_pld            [INST_DECODE_NUM-1     :0];

    //##############################################
    // package 
    //##############################################
    // assign v_fetched_instruction_rdy[7:4] = 4'b0;
    assign csr_intr_instruction_rdy = v_csr_intr_instruction_rdy[0];
    assign mext_inst_imm            = mext_pld.inst_imm;
    assign mext_instruction_idx     = mext_pld.inst_id;
    assign mext_pc                  = mext_pld.inst_pc;
    assign mext_inst_rd_idx         = mext_pld.inst_rd;
    assign mext_inst_rd_en          = mext_pld.inst_rd_en;
    assign mext_c_ext               = mext_pld.c_ext;
    assign mext_arch_reg_index      = mext_pld.arch_reg_index;
    assign mext_instruction_pld     = mext_pld.inst_pld;
    assign mext_rs1_val             = mext_pld.reg_rs1_val;
    assign mext_rs2_val             = mext_pld.reg_rs2_val;
    assign csr_inst_imm             = csr_pld.inst_imm;
    assign csr_pc                   = csr_pld.inst_pc;
    assign csr_instruction_idx      = csr_pld.inst_id;
    assign csr_inst_rd_idx          = csr_pld.inst_rd;
    assign csr_inst_rd_en           = csr_pld.inst_rd_en;
    assign csr_c_ext                = csr_pld.c_ext;
    assign csr_arch_reg_index       = csr_pld.arch_reg_index;
    assign csr_instruction_pld      = csr_pld.inst_pld;
    assign csr_rs1_val              = csr_pld.reg_rs1_val;
    assign csr_rs2_val              = csr_pld.reg_rs2_val;
    assign custom_pc                = custom_pld.inst_pc;
    assign custom_instruction_pld   = custom_pld.inst_pld;
    assign custom_rs1_val           = custom_pld.reg_rs1_val;
    assign custom_rs2_val           = custom_pld.reg_rs2_val;
    //##############################################
    // decode -8 -buffer -4
    //##############################################

    toy_dispatch_issue_buffer #(
        .OOO_DEPTH      (INST_DECODE_NUM    ),
        .S_CHANNEL      (INST_READ_CHANNEL  ),
        .BUFFER_DEPTH   (16                 )
    )
    u_toy_dispatch_issue_buffer(
        .clk            (clk                ),
        .rst_n          (rst_n              ),
        .v_s_vld        (v_dec_buffer_vld   ),
        .v_s_rdy        (v_dec_buffer_rdy   ),
        .v_s_pld        (v_dec_buffer_pld   ),
        .v_m_vld        (v_dec_inst_vld     ),
        .v_m_rdy        (v_dec_inst_rdy     ),
        .v_m_pld        (v_dec_pld          ),
        .cancel_edge_en (cancel_edge_en     )
    );


    generate
        for (genvar i=0;i<INST_READ_CHANNEL;i=i+1)begin:DECODE_GEN
            toy_decoder u_dec (
                .clk                (clk                             ),
                .rst_n              (rst_n                           ),
                .fetched_inst_vld   (v_fetched_instruction_vld[i]    ),
                .fetched_inst_rdy   (v_fetched_instruction_rdy[i]    ),
                .fetched_inst_pld   (v_fetched_instruction_pld[i]    ), 
                .fetched_inst_pc    (v_fetched_instruction_pc[i]     ),
                .fetched_inst_id    (v_fetched_instruction_idx[i]    ),
                .csr_intr_instruction_vld(csr_intr_instruction_vld   ),
                .csr_intr_instruction_rdy(v_csr_intr_instruction_rdy[i]),
                .decode_pld         (v_dec_buffer_pld[i]             ),
                .dec_inst_vld       (v_dec_buffer_vld[i]             ),
                .dec_inst_rdy       (v_dec_buffer_rdy[i]             )
                // .dec_inst_pld       (v_dec_inst_pld[i]               ),
                // .dec_inst_id        (v_dec_inst_id[i]                ),
                // .dec_inst_rd        (v_dec_inst_rd[i]                ),
                // .dec_inst_rd_en     (v_dec_inst_rd_en[i]             ),
                // .dec_inst_fp_rd_en  (v_dec_inst_fp_rd_en[i]          ),
                // .dec_inst_pc        (v_dec_inst_pc[i]                ),
                // .dec_inst_c_ext     (v_dec_inst_c_ext[i]             ),
                // .dec_inst_rs1       (v_dec_inst_rs1[i]               ),
                // .dec_inst_rs2       (v_dec_inst_rs2[i]               ),
                // .dec_inst_rs3       (v_dec_inst_rs3[i]               ),
                // .use_rs1_en         (v_use_rs1_en[i]                 ),
                // .use_rs2_en         (v_use_rs2_en[i]                 ),
                // .use_rs1_fp_en      (v_use_rs1_fp_en[i]              ),
                // .use_rs2_fp_en      (v_use_rs2_fp_en[i]              ),
                // .use_rs3_fp_en      (v_use_rs3_fp_en[i]              ),  
                // .dec_inst_imm       (v_dec_inst_imm[i]               ),
                // .dec_inst_is_intr   (v_dec_inst_is_intr[i]           ),
                // .goto_lsu           (v_goto_lsu[i]                   ),
                // .goto_ldu           (v_goto_ldu[i]                   ),
                // .goto_stu           (v_goto_stu[i]                   ),
                // .goto_alu           (v_goto_alu[i]                   ),
                // .goto_err           (v_goto_err[i]                   ),
                // .goto_mext          (v_goto_mext[i]                  ),
                // .goto_csr           (v_goto_csr[i]                   ),
                // .goto_float         (v_goto_float[i]                 ),
                // .goto_custom        (v_goto_custom[i]                )
                );
            if(i<4)begin:ALU_INST_GEN

                assign v_dec_inst_pld[i]             = v_dec_pld[i].inst_pld       ;  
                assign v_dec_inst_id[i]              = v_dec_pld[i].inst_id        ;  
                assign v_dec_inst_rd[i]              = v_dec_pld[i].inst_rd        ;  
                assign v_dec_inst_rd_en[i]           = v_dec_pld[i].inst_rd_en     ;  
                assign v_dec_inst_fp_rd_en[i]        = v_dec_pld[i].inst_fp_rd_en  ;  
                assign v_dec_inst_c_ext[i]           = v_dec_pld[i].c_ext          ;  
                assign v_dec_inst_pc[i]              = v_dec_pld[i].inst_pc        ;  
                assign v_dec_inst_rs1[i]             = v_dec_pld[i].reg_rs1        ;  
                assign v_dec_inst_rs2[i]             = v_dec_pld[i].reg_rs2        ;  
                assign v_dec_inst_rs3[i]             = v_dec_pld[i].reg_rs3        ;  
                assign v_dec_inst_imm[i]             = v_dec_pld[i].inst_imm       ;  
                assign v_goto_lsu[i]                 = v_dec_pld[i].goto_lsu       ;  
                assign v_goto_ldu[i]                 = v_dec_pld[i].goto_ldu       ;  
                assign v_goto_stu[i]                 = v_dec_pld[i].goto_stu       ;  
                assign v_goto_alu[i]                 = v_dec_pld[i].goto_alu       ;  
                assign v_goto_err[i]                 = v_dec_pld[i].goto_err       ;  
                assign v_goto_mext[i]                = v_dec_pld[i].goto_mext      ;  
                assign v_goto_csr[i]                 = v_dec_pld[i].goto_csr       ;  
                assign v_goto_float[i]               = v_dec_pld[i].goto_float     ;  
                assign v_goto_custom[i]              = v_dec_pld[i].goto_custom    ;  
                assign v_use_rs1_fp_en[i]            = v_dec_pld[i].use_rs1_fp_en  ;  
                assign v_use_rs2_fp_en[i]            = v_dec_pld[i].use_rs2_fp_en  ;  
                assign v_use_rs3_fp_en[i]            = v_dec_pld[i].use_rs3_fp_en  ;  
                assign v_use_rs1_en[i]               = v_dec_pld[i].use_rs1_en     ;  
                assign v_use_rs2_en[i]               = v_dec_pld[i].use_rs2_en     ;  

                assign v_alu_instruction_vld[i]                 = v_goto_alu[i] && v_eu_vld[i] ;
                assign v_alu_instruction_pld[i].inst_imm        = v_dec_inst_imm[i];
                assign v_alu_instruction_pld[i].inst_pc         = v_dec_inst_pc[i];
                assign v_alu_instruction_pld[i].inst_id         = v_dec_inst_id[i];
                assign v_alu_instruction_pld[i].inst_rd         = v_int_phy_reg_rd_index[i];
                assign v_alu_instruction_pld[i].inst_rd_en      = v_dec_inst_rd_en[i];
                assign v_alu_instruction_pld[i].arch_reg_index  = v_dec_inst_rd[i];
                assign v_alu_instruction_pld[i].inst_pld        = v_dec_inst_pld[i];
                assign v_alu_instruction_pld[i].reg_rs1_val     = v_reg_rs1_val[i];
                assign v_alu_instruction_pld[i].reg_rs2_val     = v_reg_rs2_val[i]; 
                assign v_alu_instruction_pld[i].c_ext           = v_dec_inst_c_ext[i]; 
                
                assign v_lsu_instruction_vld[i]      = v_goto_lsu[i] && v_eu_vld[i] ;
                assign v_lsu_pld[i].inst_pld         = v_dec_inst_pld[i]            ;
                assign v_lsu_pld[i].inst_id          = v_dec_inst_id[i]             ;
                assign v_lsu_pld[i].inst_rd          = v_dec_inst_rd_en[i] ? v_int_phy_reg_rd_index[i] : v_fp_phy_reg_rd_index[i] ;
                assign v_lsu_pld[i].inst_rd_en       = v_dec_inst_rd_en[i]          ;
                assign v_lsu_pld[i].inst_fp_rd_en    = v_dec_inst_fp_rd_en[i]       ;
                assign v_lsu_pld[i].arch_reg_index   = v_dec_inst_rd[i];
                assign v_lsu_pld[i].inst_pc          = v_dec_inst_pc[i]             ;
                assign v_lsu_pld[i].reg_rs1_val      = v_reg_rs1_val[i]             ;
                assign v_lsu_pld[i].reg_rs2_val      = v_use_rs2_fp_en[i] ? v_fp_reg_rs2_val[i] : v_reg_rs2_val[i];
                assign v_lsu_pld[i].reg_rs3_val      = v_fp_reg_rs3_val[i]          ;
                assign v_lsu_pld[i].inst_imm         = v_dec_inst_imm[i]            ;
                assign v_lsu_pld[i].stu_en           = v_goto_stu[i]                ;
                assign v_lsu_pld[i].ldu_en           = v_goto_ldu[i]                ;
                assign v_lsu_pld[i].c_ext            = v_dec_inst_c_ext[i]          ;
            end 
        end
    endgenerate

    //==========================================================================
    // Reg File
    //==========================================================================

    assign v_int_wr_en = {v_lsu_reg_wr_en[2],v_lsu_reg_wr_en[1],v_lsu_reg_wr_en[0],float_reg_wr_en,csr_reg_wr_en,mext_reg_wr_en,v_alu_reg_wr_en};
    assign v_fp_wr_en  = {v_lsu_fp_reg_wr_en[2],v_lsu_fp_reg_wr_en[1],v_lsu_fp_reg_wr_en[0],float_fp_reg_wr_en,6'b0};




    assign v_wr_reg_index[9] =  v_lsu_reg_index[2];
    assign v_wr_reg_index[8] =  v_lsu_reg_index[1];
    assign v_wr_reg_index[7] =  v_lsu_reg_index[0];
    assign v_wr_reg_index[6] =  float_reg_index;
    assign v_wr_reg_index[5] =  csr_reg_index;
    assign v_wr_reg_index[4] =  mext_reg_index;
    assign v_wr_reg_index[3] =  v_alu_reg_index[3];
    assign v_wr_reg_index[2] =  v_alu_reg_index[2];
    assign v_wr_reg_index[1] =  v_alu_reg_index[1];
    assign v_wr_reg_index[0] =  v_alu_reg_index[0];

    assign v_wr_reg_data[9] =  v_lsu_reg_val[2];
    assign v_wr_reg_data[8] =  v_lsu_reg_val[1];
    assign v_wr_reg_data[7] =  v_lsu_reg_val[0];
    assign v_wr_reg_data[6] =  float_reg_val;
    assign v_wr_reg_data[5] =  csr_reg_val;
    assign v_wr_reg_data[4] =  mext_reg_val;
    assign v_wr_reg_data[3] =  v_alu_reg_val[3];
    assign v_wr_reg_data[2] =  v_alu_reg_val[2];
    assign v_wr_reg_data[1] =  v_alu_reg_val[1];
    assign v_wr_reg_data[0] =  v_alu_reg_val[0];

    // int reg file ================================================================
    toy_regfile #(
        .MODE                (0                         )
    )u_int_regfile(
        .clk                 (clk                       ),
        .rst_n               (rst_n                     ),
        .v_pre_allocate_vld  (v_int_pre_allocate_vld    ),
        .v_pre_allocate_rdy  (v_int_pre_allocate_rdy    ),
        .v_pre_allocate_zero (v_int_pre_allocate_zero   ),
        .v_pre_allocate_id   (v_int_pre_allocate_id     ),
        .v_phy_reg_rd_index  (v_int_phy_reg_rd_index    ),
        .cancel_edge_en      (cancel_edge_en            ),
        .v_commit_en         (v_commit_en               ),
        .v_commit_pld        (v_commit_pld              ),
        .v_reg_rd_en         (v_int_reg_rd_en           ),
        .v_reg_rd_index      (v_dec_inst_rd             ),
        .v_reg_rd_allocate_id(v_int_rd_phy_id           ),
        .v_reg_rs1_index     (v_dec_inst_rs1            ),
        .v_reg_rs2_index     (v_dec_inst_rs2            ),
        .v_reg_rs3_index     (v_dec_inst_rs3            ),
        .v_reg_rs1_data      (v_reg_rs1_val             ),
        .v_reg_rs2_data      (v_reg_rs2_val             ),
        .v_reg_rs3_data      (                          ),
        .v_reg_rs1_rdy       (v_int_reg_rs1_rdy         ),
        .v_reg_rs2_rdy       (v_int_reg_rs2_rdy         ),
        .v_reg_rs3_rdy       (                          ),
        .v_wr_en             (v_int_wr_en               ),
        .v_wr_reg_index      (v_wr_reg_index            ),
        .v_wr_reg_data       (v_wr_reg_data             )
    );
    // fp reg file  ================================================================
    toy_regfile#(
        .MODE                (1                         )    
    )u_fp_regfile(
        .clk                 (clk                       ),
        .rst_n               (rst_n                     ),
        .v_pre_allocate_vld  (v_fp_pre_allocate_vld     ),
        .v_pre_allocate_rdy  (v_fp_pre_allocate_rdy     ),
        .v_pre_allocate_zero (                          ),
        .v_pre_allocate_id   (v_fp_pre_allocate_id      ),
        .v_phy_reg_rd_index  (v_fp_phy_reg_rd_index     ),
        .cancel_edge_en      (cancel_edge_en            ),
        .v_commit_en         (v_commit_en               ),
        .v_commit_pld        (v_commit_pld              ),
        .v_reg_rd_en         (v_fp_reg_rd_en            ),
        .v_reg_rd_index      (v_dec_inst_rd             ),
        .v_reg_rd_allocate_id(v_fp_rd_phy_id            ),
        .v_reg_rs1_index     (v_dec_inst_rs1            ),
        .v_reg_rs2_index     (v_dec_inst_rs2            ),
        .v_reg_rs3_index     (v_dec_inst_rs3            ),
        .v_reg_rs1_data      (v_fp_reg_rs1_val          ),
        .v_reg_rs2_data      (v_fp_reg_rs2_val          ),
        .v_reg_rs3_data      (v_fp_reg_rs3_val          ),
        .v_reg_rs1_rdy       (v_fp_reg_rs1_rdy          ),
        .v_reg_rs2_rdy       (v_fp_reg_rs2_rdy          ),
        .v_reg_rs3_rdy       (v_fp_reg_rs3_rdy          ),
        .v_wr_en             (v_fp_wr_en                ),
        .v_wr_reg_index      (v_wr_reg_index            ),
        .v_wr_reg_data       (v_wr_reg_data             )
    );


    //##############################################
    // hazard 
    //##############################################
    toy_dispatch_issue u_toy_dispatch_issue
    (
        .clk                   (clk                    ),
        .rst_n                 (rst_n                  ),
        .v_dec_inst_vld        (v_dec_inst_vld         ),
        .v_dec_inst_rdy        (v_dec_inst_rdy         ),

        .v_dec_inst_rd_en      (v_dec_inst_rd_en       ),
        .v_dec_inst_fp_rd_en   (v_dec_inst_fp_rd_en    ),
        .v_dec_inst_rd         (v_dec_inst_rd          ),
        .v_dec_inst_rs1        (v_dec_inst_rs1         ),
        .v_dec_inst_rs2        (v_dec_inst_rs2         ),
        .v_dec_inst_rs3        (v_dec_inst_rs3         ),

        .v_use_rs1_fp_en       (v_use_rs1_fp_en        ),
        .v_use_rs2_fp_en       (v_use_rs2_fp_en        ),
        .v_use_rs3_fp_en       (v_use_rs3_fp_en        ),
        .v_use_rs1_en          (v_use_rs1_en           ),
        .v_use_rs2_en          (v_use_rs2_en           ),

        .v_goto_lsu            (v_goto_lsu             ),
        .v_goto_alu            (v_goto_alu             ),
        .v_goto_err            (v_goto_err             ),
        .v_goto_mext           (v_goto_mext            ),
        .v_goto_float          (v_goto_float           ),
        .v_goto_csr            (v_goto_csr             ),
        .v_goto_custom         (v_goto_custom          ),

        .csr_lock              (csr_lock               ),
        .v_int_reg_rs1_rdy     (v_int_reg_rs1_rdy      ),
        .v_int_reg_rs2_rdy     (v_int_reg_rs2_rdy      ),
        .v_fp_reg_rs1_rdy      (v_fp_reg_rs1_rdy       ),
        .v_fp_reg_rs2_rdy      (v_fp_reg_rs2_rdy       ),
        .v_fp_reg_rs3_rdy      (v_fp_reg_rs3_rdy       ),
        .v_int_pre_allocate_vld(v_int_pre_allocate_vld ),
        .v_fp_pre_allocate_vld (v_fp_pre_allocate_vld  ),
        .v_int_pre_allocate_id (v_int_pre_allocate_id  ),
        .v_fp_pre_allocate_id  (v_fp_pre_allocate_id   ),
        .v_int_pre_allocate_rdy(v_int_pre_allocate_rdy ),
        .v_fp_pre_allocate_rdy (v_fp_pre_allocate_rdy  ),
        .v_int_pre_allocate_zero(v_int_pre_allocate_zero),
        .v_int_rd_phy_id       (v_int_rd_phy_id        ),
        .v_fp_rd_phy_id        (v_fp_rd_phy_id         ),
        .v_int_reg_rd_en       (v_int_reg_rd_en        ),
        .v_fp_reg_rd_en        (v_fp_reg_rd_en         ),
        .v_eu_vld              (v_eu_vld               ),
        .v_alu_instruction_rdy (v_alu_instruction_rdy  ),
        .v_lsu_instruction_rdy (v_lsu_instruction_rdy  ),
        .mext_instruction_rdy  (mext_instruction_rdy   ),
        .float_instruction_rdy (float_instruction_rdy  ),
        .csr_instruction_rdy   (csr_instruction_rdy    ),
        .custom_instruction_rdy(custom_instruction_rdy ));


    //##############################################
    // crossbar 
    //##############################################
    toy_dispatch_crossbar u_toy_dispatch_crossbar
    (
        .clk                   (clk                    ),
        .rst_n                 (rst_n                  ),
        .v_eu_vld              (v_eu_vld               ),
        .v_dec_inst_rd_en      (v_dec_inst_rd_en       ),
        .v_dec_inst_fp_rd_en   (v_dec_inst_fp_rd_en    ),
        .v_dec_inst_pld        (v_dec_inst_pld         ),
        .v_dec_inst_id         (v_dec_inst_id          ),
        .v_arch_reg_rd_index   (v_dec_inst_rd          ),
        .v_int_phy_reg_rd_index(v_int_phy_reg_rd_index ),
        .v_fp_phy_reg_rd_index (v_fp_phy_reg_rd_index  ),
        .v_dec_inst_pc         (v_dec_inst_pc          ),
        .v_dec_inst_imm        (v_dec_inst_imm         ), 
        .v_dec_inst_c_ext      (v_dec_inst_c_ext       ),
        .v_reg_rs1_val         (v_reg_rs1_val          ),
        .v_reg_rs2_val         (v_reg_rs2_val          ),
        .v_fp_reg_rs1_val      (v_fp_reg_rs1_val       ),
        .v_fp_reg_rs2_val      (v_fp_reg_rs2_val       ),
        .v_fp_reg_rs3_val      (v_fp_reg_rs3_val       ),
        .v_use_rs1_fp_en       (v_use_rs1_fp_en        ),
        .v_use_rs2_fp_en       (v_use_rs2_fp_en        ),
        // .v_goto_lsu            (v_goto_lsu             ),
        .v_goto_err            (v_goto_err             ),
        .v_goto_mext           (v_goto_mext            ),
        .v_goto_float          (v_goto_float           ),
        .v_goto_csr            (v_goto_csr             ),
        .v_goto_custom         (v_goto_custom          ),
        // .lsu_instruction_vld   (lsu_instruction_vld    ),
        // .lsu_pld               (lsu_pld                ),
        .mext_instruction_vld  (mext_instruction_vld   ),
        .mext_pld              (mext_pld               ),
        .float_instruction_vld (float_instruction_vld  ),
        .float_pld             (float_instruction_pld  ),
        .csr_instruction_vld   (csr_instruction_vld    ),
        .csr_pld               (csr_pld                ),
        .custom_instruction_vld(custom_instruction_vld ),
        .custom_pld            (custom_pld             ));


    assign csr_instruction_is_intr  = | v_dec_inst_is_intr;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            csr_lock <= 0;
        end
        else if(cancel_edge_en)begin
            csr_lock <= 0;
        end
        else if(float_inst_commit_en | csr_inst_commit_en)begin
            csr_lock <= 0;
        end
        else if(|((v_eu_vld & v_dec_inst_rdy) & (v_goto_csr | v_goto_float)) )begin
            csr_lock <= 1;
        end
    end


    // DEBUG =========================================================================================================

    `ifdef TOY_SIM


    initial begin
        if($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk)

                $display("===");
                $display("register_lock         = %b" , register_lock);
                $display("register_lock_release = %b" , register_lock_release);
                // for (int x =0 ;x<4;x=x+1)begin
                //     if(v_fetched_instruction_vld[x] && v_fetched_instruction_rdy[x]) begin
                //         $display("[dispatch] receive instruction %h, decode goto_alu=%0d, goto_lsu=%0d." , v_fetched_instruction_pld[x],v_goto_alu[x],v_goto_lsu[x]);
                //     end

                //     if(v_alu_instruction_vld[x] && v_alu_instruction_rdy[x]) begin
                //         $display("[dispatch] issue instruction %h to alu." , v_alu_instruction_pld[x]);
                //         $display("[dispatch] rs1=%0d, rs2=%0d." , v_dec_inst_rs1[x], v_dec_inst_rs2[x]);
                //         $display("[dispatch] rs1_val=0x%h, rs2_val=0x%h." , v_alu_rs1_val[x], v_alu_rs2_val[x]);
                //     end
                // end
                // if(|(v_lsu_instruction_vld & v_lsu_instruction_rdy)) begin
                //     $display("[dispatch] issue instruction %h to lsu." , lsu_instruction_pld);
                // end
                


                // if (reg_wr_en) begin
                //     $display("[dispatch] wb reg[%0d] = %h" , reg_index,reg_val);
                // end

            end
        end
    end

    logic [31:0] reg_stall;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) reg_stall <= 32'b0;
        else if(~|v_fetched_instruction_rdy) reg_stall <= reg_stall + 1;
    end


    logic [REG_WIDTH-1:0] registers_shadow            [0:31]  ;
    logic [REG_WIDTH-1:0] fp_registers_shadow         [0:31]  ;
    logic [4:0] int_rename_id         [0:31]  ;
    logic [4:0] fp_rename_id          [0:31]  ;

    logic [31:0] int_phy_data         [95:0]  ;
    logic [31:0] fp_phy_data          [95:0]  ;


    logic [INST_WIDTH-1:0] fetched_instruction_pld_lut  [0:(1<<INST_IDX_WIDTH)-1];
    logic [ADDR_WIDTH-1:0] fetched_instruction_pc_lut   [0:(1<<INST_IDX_WIDTH)-1];

    function string print_all_reg_shadow();
        string res;
        $sformat(res, "zo:%h ra:%h sp:%h gp:%h tp:%h t0:%h t1:%h t2:%h s0:%h s1:%h a0:%h a1:%h a2:%h a3:%h a4:%h a5:%h a6:%h a7:%h s2:%h s3:%h s4:%h s5:%h s6:%h s7:%h s8:%h s9:%h s10:%h s11:%h t3:%h t4:%h t5:%h t6:%h \n fp0:%h fp1:%h fp2:%h fp3:%h fp4:%h fp5:%h fp6:%h fp7:%h fp8:%h fp9:%h fp10:%h fp11:%h fp12:%h fp13:%h fp14:%h fp15:%h fp16:%h fp17:%h fp18:%h fp19:%h fp20:%h fp21:%h fp22:%h fp23:%h fp24:%h fp25:%h fp26:%h fp27:%h fp28:%h fp29:%h fp30:%h fp31:%h", 
            registers_shadow[0]  ,
            registers_shadow[1]  ,
            registers_shadow[2]  ,
            registers_shadow[3]  ,
            registers_shadow[4]  ,
            registers_shadow[5]  ,
            registers_shadow[6]  ,
            registers_shadow[7]  ,
        
            registers_shadow[8]  ,
            registers_shadow[9]  ,
            registers_shadow[10] ,
            registers_shadow[11] ,
            registers_shadow[12] ,
            registers_shadow[13] ,
            registers_shadow[14] ,
            registers_shadow[15] ,
        
            registers_shadow[16] ,
            registers_shadow[17] ,
            registers_shadow[18] ,
            registers_shadow[19] ,
            registers_shadow[20] ,
            registers_shadow[21] ,
            registers_shadow[22] ,
            registers_shadow[23] ,

            registers_shadow[24] ,
            registers_shadow[25] ,
            registers_shadow[26] ,
            registers_shadow[27] ,
            registers_shadow[28] ,
            registers_shadow[29] ,
            registers_shadow[30] ,
            registers_shadow[31] ,

            fp_registers_shadow[0]  ,
            fp_registers_shadow[1]  ,
            fp_registers_shadow[2]  ,
            fp_registers_shadow[3]  ,
            fp_registers_shadow[4]  ,
            fp_registers_shadow[5]  ,
            fp_registers_shadow[6]  ,
            fp_registers_shadow[7]  ,
        
            fp_registers_shadow[8]  ,
            fp_registers_shadow[9]  ,
            fp_registers_shadow[10] ,
            fp_registers_shadow[11] ,
            fp_registers_shadow[12] ,
            fp_registers_shadow[13] ,
            fp_registers_shadow[14] ,
            fp_registers_shadow[15] ,
        
            fp_registers_shadow[16] ,
            fp_registers_shadow[17] ,
            fp_registers_shadow[18] ,
            fp_registers_shadow[19] ,
            fp_registers_shadow[20] ,
            fp_registers_shadow[21] ,
            fp_registers_shadow[22] ,
            fp_registers_shadow[23] ,

            fp_registers_shadow[24] ,
            fp_registers_shadow[25] ,
            fp_registers_shadow[26] ,
            fp_registers_shadow[27] ,
            fp_registers_shadow[28] ,
            fp_registers_shadow[29] ,
            fp_registers_shadow[30] ,
            fp_registers_shadow[31]             
            );
        return res;
    endfunction

    initial begin
        int file_handle;
        for(int i=0;i<32;i=i+1) begin
            registers_shadow[i] = 0;
        end

        file_handle = $fopen("sim_trace.log", "w");
        forever begin
            @(posedge clk)

            // update reorder buffer ===========================================================
            if(v_fetched_instruction_vld[0] && v_fetched_instruction_rdy[0]) begin
                fetched_instruction_pld_lut[v_fetched_instruction_idx[0]] = v_fetched_instruction_pld[0];
                fetched_instruction_pc_lut[v_fetched_instruction_idx[0]]  = v_fetched_instruction_pc[0];
            end 

            // update shadowreg file ===========================================================
            for(int j=0;j<96;j=j+1) begin
                int_phy_data[j] = u_toy_scalar.u_core.u_dispatch.u_int_regfile.u_toy_physicial_regfile.v_reg_phy_data[j];
                fp_phy_data[j] = u_toy_scalar.u_core.u_dispatch.u_fp_regfile.u_toy_physicial_regfile.v_reg_phy_data[j];
            end
            for(int i=0;i<32;i=i+1) begin
                int_rename_id[i] = u_toy_scalar.u_core.u_dispatch.u_int_regfile.u_rename_reg_file.v_reg_phy_id[i];
                fp_rename_id[i] = u_toy_scalar.u_core.u_dispatch.u_fp_regfile.u_rename_reg_file.v_reg_phy_id[i];
                registers_shadow[i] = int_phy_data[int_rename_id[i]];
                fp_registers_shadow[i] = fp_phy_data[fp_rename_id[i]];
            end


            // if(lsu_inst_commit_en_rd) begin
            //     $fdisplay(file_handle, "[pc=%h][%s]", fetched_instruction_pc_lut[lsu_reg_inst_idx_rd] ,  print_all_reg_shadow());
            //     if(lsu_reg_wr_en)
            //         registers_shadow[lsu_reg_index] = lsu_reg_val;
            // end

            if(v_alu_inst_commit_en[0]) begin
                $fdisplay(file_handle, "[pc=%h][%s]", fetched_instruction_pc_lut[v_alu_reg_inst_idx[0]]    ,  print_all_reg_shadow());
            end
            
            if(mext_inst_commit_en) begin
                $fdisplay(file_handle, "[pc=%h][%s]", fetched_instruction_pc_lut[mext_reg_inst_idx]   ,  print_all_reg_shadow());
            end
            
            if(csr_inst_commit_en) begin
                $fdisplay(file_handle, "[pc=%h][%s]", fetched_instruction_pc_lut[csr_reg_inst_idx]    ,  print_all_reg_shadow());        
            end
            
            // if(lsu_inst_commit_en_wr)begin
            //     $fdisplay(file_handle, "[pc=%h][%s]", fetched_instruction_pc_lut[lsu_reg_inst_idx_wr] ,  print_all_reg_shadow());
            // end
        end
    end

    logic [31:0] fetch_entry_cnt [3:0];
    generate
        for(genvar a=0;a<4;a=a+1)begin
            always_ff @(posedge clk or negedge rst_n) begin:FETCH_ENTRY_CNT_FOR_SIM
                if(~rst_n)begin
                    fetch_entry_cnt[a] <= 32'b0;
                end
                else if(v_fetched_instruction_vld[a] && v_fetched_instruction_rdy[a])begin
                    fetch_entry_cnt[a] <= fetch_entry_cnt[a] + 1'b1;
                end
            end
        end
    endgenerate

    logic [31:0] fetch_0_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            fetch_0_cnt <= 32'b0;
        end
        else if(~|(v_fetched_instruction_vld & v_fetched_instruction_rdy))begin
            fetch_0_cnt <= fetch_0_cnt + 1'b1;
        end
        
    end

    // logic dispatch_req_handshake;
    // assign dispatch_req_handshake = v_fetched_instruction_vld && v_fetched_instruction_rdy;
    
    // initial begin
    //   forever begin
    //       @(posedge clk)
    //       if(dispatch_req_handshake)begin
    //          $display("Dispatch req handshake success!!!");
    //          $display("Dispatch fetch pc is [%h], inst is [%h]",v_fetched_instruction_pc[0],v_fetched_instruction_pld[0]);
    //       end
    //   end
    // end

    `endif


endmodule
