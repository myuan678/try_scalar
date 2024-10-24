

module toy_dispatch_crossbar
    import toy_pack::*;
(
    input  logic                                 clk                     ,
    input  logic                                 rst_n                   ,

    input  logic [INST_DECODE_NUM-1    :0]       v_eu_vld                ,

    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_rd_en        ,
    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_fp_rd_en     ,
    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_c_ext        ,
    input  logic [4                    :0]       v_arch_reg_rd_index    [INST_DECODE_NUM-1    :0] ,
    input  logic [PHY_REG_ID_WIDTH-1   :0]       v_int_phy_reg_rd_index [INST_DECODE_NUM-1    :0] ,
    input  logic [PHY_REG_ID_WIDTH-1   :0]       v_fp_phy_reg_rd_index  [INST_DECODE_NUM-1    :0] ,
    input  logic [INST_WIDTH-1         :0]       v_dec_inst_pld         [INST_DECODE_NUM-1    :0] ,
    input  logic [INST_IDX_WIDTH-1     :0]       v_dec_inst_id          [INST_DECODE_NUM-1    :0] ,
    input  logic [ADDR_WIDTH-1         :0]       v_dec_inst_pc          [INST_DECODE_NUM-1    :0] ,
    input  logic [31                   :0]       v_dec_inst_imm         [INST_DECODE_NUM-1    :0] ,   
    input  logic [31                   :0]       v_reg_rs1_val          [INST_DECODE_NUM-1    :0] ,
    input  logic [31                   :0]       v_reg_rs2_val          [INST_DECODE_NUM-1    :0] ,
    input  logic [31                   :0]       v_fp_reg_rs1_val       [INST_DECODE_NUM-1    :0] ,
    input  logic [31                   :0]       v_fp_reg_rs2_val       [INST_DECODE_NUM-1    :0] ,
    input  logic [31                   :0]       v_fp_reg_rs3_val       [INST_DECODE_NUM-1    :0] , 

    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs1_fp_en         ,    
    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs2_fp_en         ,    

    // input  logic [INST_DECODE_NUM-1    :0]       v_goto_lsu              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_err              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_mext             ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_float            ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_csr              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_custom           ,
 
    // output logic                                 lsu_instruction_vld     ,
    // output eu_pkg                                lsu_pld                 ,
    output logic                                 mext_instruction_vld    ,
    output eu_pkg                                mext_pld                ,
    output logic                                 float_instruction_vld   ,
    output eu_pkg                                float_pld               ,
    output logic                                 csr_instruction_vld     ,
    output eu_pkg                                csr_pld                 ,
    output logic                                 custom_instruction_vld  ,
    output eu_pkg                                custom_pld

);
    //##############################################
    // logic 
    //############################################## 
    // logic [INST_DECODE_NUM-1    :0]     onehot_lsu              ;
    logic [INST_DECODE_NUM-1    :0]     onehot_mext             ;
    logic [INST_DECODE_NUM-1    :0]     onehot_float            ;
    logic [INST_DECODE_NUM-1    :0]     onehot_csr              ;
    logic [INST_DECODE_NUM-1    :0]     onehot_custom           ;
    //##############################################
    // package
    //############################################## 
    // eu_pkg v_lsu_pld        [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_mext_pld       [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_float_pld      [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_csr_pld        [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_custom_pld     [INST_DECODE_NUM-1    :0]           ;
    // eu_pkg v_lsu_pld_arb    [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_mext_pld_arb   [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_float_pld_arb  [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_csr_pld_arb    [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_custom_pld_arb [INST_DECODE_NUM-1    :0]           ;
    // eu_pkg v_lsu_pld_or     [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_mext_pld_or    [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_float_pld_or   [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_csr_pld_or     [INST_DECODE_NUM-1    :0]           ;
    eu_pkg v_custom_pld_or  [INST_DECODE_NUM-1    :0]           ;

    //##############################################
    // package logic
    //############################################## 
    // assign lsu_pld               = v_lsu_pld_or[INST_DECODE_NUM-1]      ;
    assign mext_pld              = v_mext_pld_or[INST_DECODE_NUM-1]     ;
    assign float_pld             = v_float_pld_or[INST_DECODE_NUM-1]    ;
    assign csr_pld               = v_csr_pld_or[INST_DECODE_NUM-1]      ;
    assign custom_pld            = v_custom_pld_or[INST_DECODE_NUM-1]   ;

    // assign lsu_instruction_vld   = |onehot_lsu                          ;
    assign mext_instruction_vld  = |onehot_mext                         ;
    assign float_instruction_vld = |onehot_float                        ;
    assign csr_instruction_vld   = |onehot_csr                          ;
    assign custom_instruction_vld= |onehot_custom                       ;
    //##############################################
    // cross bar
    //############################################## 
    generate
        for (genvar i=0;i<INST_DECODE_NUM;i=i+1)begin : DECODE_GEN
            if(i==0)begin
                // assign v_lsu_pld_or[0] = v_lsu_pld_arb[i];
                assign v_mext_pld_or[0] = v_mext_pld_arb[i];
                assign v_float_pld_or[0] = v_float_pld_arb[i];
                assign v_csr_pld_or[0] = v_csr_pld_arb[i];
                assign v_custom_pld_or[0] = v_custom_pld_arb[i];
            end
            else begin
                // assign v_lsu_pld_or[i] = v_lsu_pld_or[i-1] | v_lsu_pld_arb[i];
                assign v_mext_pld_or[i] = v_mext_pld_or[i-1] | v_mext_pld_arb[i];
                assign v_csr_pld_or[i] = v_csr_pld_or[i-1] | v_csr_pld_arb[i];
                assign v_custom_pld_or[i] = v_custom_pld_or[i-1] | v_custom_pld_arb[i];
                assign v_float_pld_or[i] = v_float_pld_or[i-1] | v_float_pld_arb[i];
            end

            // assign v_lsu_pld[i].inst_pld                   = v_dec_inst_pld[i]          ;
            // assign v_lsu_pld[i].inst_id                    = v_dec_inst_id[i]           ;
            // assign v_lsu_pld[i].inst_rd                    = v_dec_inst_rd_en[i] ? v_int_phy_reg_rd_index[i] : v_fp_phy_reg_rd_index[i] ;
            // assign v_lsu_pld[i].inst_rd_en                 = v_dec_inst_rd_en[i]        ;
            // assign v_lsu_pld[i].inst_fp_rd_en              = v_dec_inst_fp_rd_en[i]     ;
            // assign v_lsu_pld[i].inst_pc                    = v_dec_inst_pc[i]           ;
            // assign v_lsu_pld[i].reg_rs1_val                = v_reg_rs1_val[i]          ;
            // assign v_lsu_pld[i].reg_rs2_val                = v_use_rs2_fp_en[i] ? v_fp_reg_rs2_val[i] : v_reg_rs2_val[i];
            // assign v_lsu_pld[i].reg_rs3_val                = v_fp_reg_rs3_val[i]       ;
            // assign v_lsu_pld[i].inst_imm                   = v_dec_inst_imm[i]          ;

            assign v_mext_pld[i].inst_pld                  = v_dec_inst_pld[i]          ;
            assign v_mext_pld[i].inst_id                   = v_dec_inst_id[i]           ;
            assign v_mext_pld[i].inst_rd                   = v_int_phy_reg_rd_index[i]  ;
            assign v_mext_pld[i].inst_rd_en                = v_dec_inst_rd_en[i]        ;
            assign v_mext_pld[i].c_ext                     = v_dec_inst_c_ext[i]        ;
            assign v_mext_pld[i].inst_fp_rd_en             = v_dec_inst_fp_rd_en[i]     ;
            assign v_mext_pld[i].arch_reg_index            = v_arch_reg_rd_index[i]     ;
            assign v_mext_pld[i].inst_pc                   = v_dec_inst_pc[i]           ;
            assign v_mext_pld[i].reg_rs1_val               = v_reg_rs1_val[i]          ;
            assign v_mext_pld[i].reg_rs2_val               = v_reg_rs2_val[i]          ;
            assign v_mext_pld[i].reg_rs3_val               = v_fp_reg_rs3_val[i]       ;
            assign v_mext_pld[i].inst_imm                  = v_dec_inst_imm[i]          ;

            assign v_float_pld[i].inst_pld                 = v_dec_inst_pld[i]          ;
            assign v_float_pld[i].inst_id                  = v_dec_inst_id[i]           ;
            assign v_float_pld[i].inst_rd                  = v_dec_inst_rd_en[i] ? v_int_phy_reg_rd_index[i] : v_fp_phy_reg_rd_index[i] ;
            assign v_float_pld[i].inst_rd_en               = v_dec_inst_rd_en[i]        ;
            assign v_float_pld[i].c_ext                    = v_dec_inst_c_ext[i]        ;
            assign v_float_pld[i].inst_fp_rd_en            = v_dec_inst_fp_rd_en[i]     ;
            assign v_float_pld[i].arch_reg_index           = v_arch_reg_rd_index[i]     ;
            assign v_float_pld[i].inst_pc                  = v_dec_inst_pc[i]           ;
            assign v_float_pld[i].reg_rs1_val              = v_use_rs1_fp_en[i] ? v_fp_reg_rs1_val[i] : v_reg_rs1_val[i];
            assign v_float_pld[i].reg_rs2_val              = v_use_rs2_fp_en[i] ? v_fp_reg_rs2_val[i] : v_reg_rs2_val[i];
            assign v_float_pld[i].reg_rs3_val              = v_fp_reg_rs3_val[i]       ;
            assign v_float_pld[i].inst_imm                 = v_dec_inst_imm[i]          ;

            assign v_csr_pld[i].inst_pld                   = v_dec_inst_pld[i]          ;
            assign v_csr_pld[i].inst_id                    = v_dec_inst_id[i]           ;
            assign v_csr_pld[i].inst_rd                    = v_int_phy_reg_rd_index[i]  ;
            assign v_csr_pld[i].inst_rd_en                 = v_dec_inst_rd_en[i]        ;
            assign v_csr_pld[i].inst_fp_rd_en              = v_dec_inst_fp_rd_en[i]     ;
            assign v_csr_pld[i].c_ext                      = v_dec_inst_c_ext[i]        ;
            assign v_csr_pld[i].arch_reg_index             = v_arch_reg_rd_index[i]     ;
            assign v_csr_pld[i].inst_pc                    = v_dec_inst_pc[i]           ;
            assign v_csr_pld[i].reg_rs1_val                = v_reg_rs1_val[i]          ;
            assign v_csr_pld[i].reg_rs2_val                = v_reg_rs2_val[i]          ;
            assign v_csr_pld[i].reg_rs3_val                = v_fp_reg_rs3_val[i]       ;
            assign v_csr_pld[i].inst_imm                   = v_dec_inst_imm[i]          ;

            assign v_custom_pld[i].inst_pld                = v_dec_inst_pld[i]          ;
            assign v_custom_pld[i].inst_id                 = v_dec_inst_id[i]           ;
            assign v_custom_pld[i].inst_rd                 = v_int_phy_reg_rd_index[i]  ;
            assign v_custom_pld[i].inst_rd_en              = v_dec_inst_rd_en[i]        ;
            assign v_custom_pld[i].inst_fp_rd_en           = v_dec_inst_fp_rd_en[i]     ;
            assign v_custom_pld[i].c_ext                   = v_dec_inst_c_ext[i]        ;
            assign v_custom_pld[i].arch_reg_index          = v_arch_reg_rd_index[i]     ;
            assign v_custom_pld[i].inst_pc                 = v_dec_inst_pc[i]           ;
            assign v_custom_pld[i].reg_rs1_val             = v_reg_rs1_val[i]          ;
            assign v_custom_pld[i].reg_rs2_val             = v_reg_rs2_val[i]          ;
            assign v_custom_pld[i].reg_rs3_val             = v_fp_reg_rs3_val[i]       ;
            assign v_custom_pld[i].inst_imm                = v_dec_inst_imm[i]          ;

            // assign onehot_lsu[i]        = v_goto_lsu[i] && v_eu_vld[i];
            assign onehot_mext[i]       = v_goto_mext[i] && v_eu_vld[i];
            assign onehot_csr[i]        = v_goto_csr[i] && v_eu_vld[i];
            assign onehot_custom[i]     = v_goto_custom[i] && v_eu_vld[i];
            assign onehot_float[i]      = v_goto_float[i] && v_eu_vld[i];

            // assign v_lsu_pld_arb[i]     = v_lsu_pld[i] & {$bits(eu_pkg){onehot_lsu[i]}};
            assign v_mext_pld_arb[i]    = v_mext_pld[i] & {$bits(eu_pkg){onehot_mext[i]}};
            assign v_csr_pld_arb[i]     = v_csr_pld[i] & {$bits(eu_pkg){onehot_csr[i]}};
            assign v_custom_pld_arb[i]  = v_custom_pld[i] & {$bits(eu_pkg){onehot_custom[i]}};
            assign v_float_pld_arb[i]   = v_float_pld[i] & {$bits(eu_pkg){onehot_float[i]}};

        end
    endgenerate


endmodule

