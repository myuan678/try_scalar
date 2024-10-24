

module toy_dispatch_issue
    import toy_pack::*;
(
    input  logic                                 clk                     ,
    input  logic                                 rst_n                   ,
    // decode 
    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_vld          ,
    output logic [INST_DECODE_NUM-1    :0]       v_dec_inst_rdy          ,

    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_rd_en        ,
    input  logic [INST_DECODE_NUM-1    :0]       v_dec_inst_fp_rd_en     ,
    input  logic [4                    :0]       v_dec_inst_rd       [INST_DECODE_NUM-1    :0] ,
    input  logic [4                    :0]       v_dec_inst_rs1      [INST_DECODE_NUM-1    :0] ,      
    input  logic [4                    :0]       v_dec_inst_rs2      [INST_DECODE_NUM-1    :0] ,      
    input  logic [4                    :0]       v_dec_inst_rs3      [INST_DECODE_NUM-1    :0] ,     

    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs1_fp_en         ,    
    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs2_fp_en         , 
    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs3_fp_en         ,    
    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs1_en            , 
    input  logic [INST_DECODE_NUM-1    :0]       v_use_rs2_en            ,    

    input  logic [INST_DECODE_NUM-1    :0]       v_goto_lsu              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_alu              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_err              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_mext             ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_float            ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_csr              ,
    input  logic [INST_DECODE_NUM-1    :0]       v_goto_custom           ,

    input  logic                                 csr_lock                ,
    // reg file
    input  logic [INST_DECODE_NUM-1    :0]       v_int_reg_rs1_rdy       ,
    input  logic [INST_DECODE_NUM-1    :0]       v_int_reg_rs2_rdy       ,
    input  logic [INST_DECODE_NUM-1    :0]       v_fp_reg_rs1_rdy        ,
    input  logic [INST_DECODE_NUM-1    :0]       v_fp_reg_rs2_rdy        ,
    input  logic [INST_DECODE_NUM-1    :0]       v_fp_reg_rs3_rdy        ,
    
    input  logic [INST_DECODE_NUM-1    :0]       v_int_pre_allocate_vld  ,
    input  logic [INST_DECODE_NUM-1    :0]       v_fp_pre_allocate_vld   ,
    input  logic [PHY_REG_ID_WIDTH-1   :0]       v_int_pre_allocate_id   [INST_DECODE_NUM-1:0],
    input  logic [PHY_REG_ID_WIDTH-1   :0]       v_fp_pre_allocate_id    [INST_DECODE_NUM-1:0],
    output logic [INST_DECODE_NUM-1    :0]       v_int_pre_allocate_rdy  ,
    output logic [INST_DECODE_NUM-1    :0]       v_fp_pre_allocate_rdy   ,
    output logic [INST_DECODE_NUM-1    :0]       v_int_pre_allocate_zero , 

    output logic [PHY_REG_ID_WIDTH-1   :0]       v_int_rd_phy_id         [INST_DECODE_NUM-1:0],
    output logic [PHY_REG_ID_WIDTH-1   :0]       v_fp_rd_phy_id          [INST_DECODE_NUM-1:0],
    output logic [INST_DECODE_NUM-1    :0]       v_int_reg_rd_en         ,
    output logic [INST_DECODE_NUM-1    :0]       v_fp_reg_rd_en          ,

    // eu
    output logic [INST_DECODE_NUM-1    :0]       v_eu_vld                ,
    input  logic [INST_ALU_NUM-1       :0]       v_alu_instruction_rdy   ,
    input  logic [4-1                  :0]       v_lsu_instruction_rdy   ,
    input  logic                                 mext_instruction_rdy    ,
    input  logic                                 float_instruction_rdy   ,
    input  logic                                 csr_instruction_rdy     ,
    input  logic                                 custom_instruction_rdy

);

    //##############################################
    // logic
    //############################################## 
    logic [INST_DECODE_NUM-1    :0]     v_unit_lock                                     ;
    logic [INST_DECODE_NUM-1    :0]     v_reg_not_lock_comb                             ;
    logic [INST_DECODE_NUM-1    :0]     v_reg_fp_not_lock_comb                          ;
    logic [INST_DECODE_NUM-1    :0]     v_reg_not_lock                                  ;
    logic [INST_DECODE_NUM-1    :0]     v_reg_fp_not_lock                               ;
    logic [INST_DECODE_NUM-1    :0]     v_eu_vld_cycle_check                            ;
    logic [INST_DECODE_NUM-1    :0]     v_eu_rdy_cycle_check                            ;
    logic [INST_DECODE_NUM-1    :0]     v_csr_not_lock                                  ;
    logic [INST_DECODE_NUM-1    :0]     v_eu_rdy                                        ;
    logic [INST_DECODE_NUM-1    :0]     v_inorder_lsu                                   ;
    logic [INST_DECODE_NUM-1    :0]     v_lsu_not_lock                                  ;
    logic [31                   :0]     v_rs_lock_comb      [INST_DECODE_NUM-1    :0]   ;
    logic [31                   :0]     v_rs_fp_lock_comb   [INST_DECODE_NUM-1    :0]   ;
    logic [31                   :0]     v_reg_lock_comb     [INST_DECODE_NUM-1    :0]   ;
    logic [31                   :0]     v_reg_fp_lock_comb  [INST_DECODE_NUM-1    :0]   ;
    logic [4                    :0]     v_goto_unit_previous[INST_DECODE_NUM-1    :0]   ;
    logic [4                    :0]     v_goto_unit         [INST_DECODE_NUM-1    :0]   ;
    //##############################################
    // ready
    //############################################## 
    assign v_dec_inst_rdy         = v_eu_rdy                    ;
    assign v_int_reg_rd_en        = v_eu_rdy & v_eu_vld &v_dec_inst_rd_en;
    assign v_fp_reg_rd_en         = v_eu_rdy & v_eu_vld &v_dec_inst_fp_rd_en;
    assign v_int_pre_allocate_rdy = v_int_reg_rd_en             ;
    assign v_fp_pre_allocate_rdy  = v_fp_reg_rd_en              ;
    assign v_int_rd_phy_id        = v_int_pre_allocate_id       ;
    assign v_fp_rd_phy_id         = v_fp_pre_allocate_id        ;
    generate
        for (genvar i=0;i<INST_DECODE_NUM;i=i+1)begin : DECODE_GEN
        // reg lock comb create=======================================================================
            for(genvar j=0;j<32;j=j+1)begin:REGFILE_GEN
                if(i==0)begin
                    if(j==0)begin
                        assign v_reg_lock_comb[i][j]= 0;
                        assign v_rs_lock_comb[i][j]= 0;
                    end
                    else begin
                        assign v_reg_lock_comb[i][j]=  (v_dec_inst_rd[i] == j) && v_dec_inst_rd_en[i] ;
                        assign v_rs_lock_comb[i][j]= (((v_dec_inst_rs1[i] == j) && v_use_rs1_en[i]) || ((v_dec_inst_rs2[i] == j) && v_use_rs2_en[i])) && (~(v_eu_vld[i] && v_eu_rdy[i])) ;
                    end
                    assign v_reg_fp_lock_comb[i][j] =  (v_dec_inst_rd[i] == j) && v_dec_inst_fp_rd_en[i] ;
                    assign v_rs_fp_lock_comb[i][j] =  (((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i]) || ((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i]) || ((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i])) && (~(v_eu_vld[i] && v_eu_rdy[i])) ;
                end
                else begin
                    if(j==0)begin
                        assign v_reg_lock_comb[i][j]= 0;
                        assign v_rs_lock_comb[i][j]= 0;
                    end
                    else begin
                        assign v_reg_lock_comb[i][j]= v_reg_lock_comb[i-1][j] | ((v_dec_inst_rd[i] == j) && v_dec_inst_rd_en[i]) ;
                        assign v_rs_lock_comb[i][j]= v_rs_lock_comb[i-1][j] |((((v_dec_inst_rs1[i] == j) && v_use_rs1_en[i]) || ((v_dec_inst_rs2[i] == j) && v_use_rs2_en[i])) && (~(v_eu_vld[i] && v_eu_rdy[i]))) ;
                    end
                    assign v_reg_fp_lock_comb[i][j] = v_reg_fp_lock_comb[i-1][j] | ((v_dec_inst_rd[i] == j) && v_dec_inst_fp_rd_en[i]) ;
                    assign v_rs_fp_lock_comb[i][j] =  v_rs_fp_lock_comb[i-1][j] | ((((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i]) || ((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i]) || ((v_dec_inst_rs1[i] == j) && v_use_rs1_fp_en[i])) && (~(v_eu_vld[i] && v_eu_rdy[i]))) ;
                end
            end

            if(i==0)begin
                assign v_unit_lock[i] = 0;
                assign v_goto_unit_previous[i] = 0;
                assign v_reg_not_lock_comb[i] = 1'b1;
                assign v_reg_fp_not_lock_comb[i] = 1'b1;
                assign v_inorder_lsu[i] = 1'b1;
                assign v_lsu_not_lock[i] = ~v_goto_lsu[i] || (v_eu_rdy[i] & v_eu_vld[i]);
                // output vld/rdy =========================================================================
                assign v_eu_rdy[i] = v_eu_rdy_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i] && v_csr_not_lock[i];
                assign v_eu_vld[i] = v_eu_vld_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i] && v_csr_not_lock[i];
            end
            else begin
                // eu hazard =========================================================================
                assign v_goto_unit_previous[i] = v_goto_unit_previous[i-1] | v_goto_unit[i-1];
                assign v_unit_lock[i] = |(v_goto_unit[i] & v_goto_unit_previous[i]);
                // reg lock comb check ===============================================================
                assign v_reg_not_lock_comb[i] = ( ~v_reg_lock_comb[i-1][v_dec_inst_rs1[i]] || ~v_use_rs1_en[i]       ) && 
                                                ( ~v_reg_lock_comb[i-1][v_dec_inst_rs2[i]] || ~v_use_rs2_en[i]       ) &&
                                                ( ~v_reg_lock_comb[i-1][v_dec_inst_rd[i]]  || ~v_dec_inst_rd_en[i]   ) && 
                                                ( ~v_rs_lock_comb[i-1][v_dec_inst_rd[i]]   || ~v_dec_inst_rd_en[i]   )  ;

                assign v_reg_fp_not_lock_comb[i]  = (~v_reg_fp_lock_comb[i-1][v_dec_inst_rs1[i]] || ~v_use_rs1_fp_en[i]    ) &&
                                                    (~v_reg_fp_lock_comb[i-1][v_dec_inst_rs2[i]] || ~v_use_rs2_fp_en[i]    ) &&
                                                    (~v_reg_fp_lock_comb[i-1][v_dec_inst_rs3[i]] || ~v_use_rs3_fp_en[i]    ) &&
                                                    (~v_reg_fp_lock_comb[i-1][v_dec_inst_rd[i]]  || ~v_dec_inst_fp_rd_en[i]) &&
                                                    ( ~v_rs_fp_lock_comb[i-1][v_dec_inst_rd[i]]  || ~v_dec_inst_fp_rd_en[i])  ;
                // output lsu inorder =================================================================
                assign v_lsu_not_lock[i] = ~v_goto_lsu[i] || (v_eu_rdy[i] & v_eu_vld[i]);
                assign v_inorder_lsu[i] = ~v_goto_lsu[i] || (&v_lsu_not_lock[i-1:0]);

                // output vld/rdy =========================================================================
                // assign v_eu_rdy[i] = (v_eu_vld[i-1] & v_eu_rdy[i-1]) && v_eu_rdy_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i];
                // assign v_eu_vld[i] = (v_eu_vld[i-1] & v_eu_rdy[i-1]) && v_eu_vld_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i];                    
                assign v_eu_rdy[i] = v_inorder_lsu[i] && v_eu_rdy_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i] && v_csr_not_lock[i];
                assign v_eu_vld[i] = v_inorder_lsu[i] && v_eu_vld_cycle_check[i] && ~v_unit_lock[i] && v_reg_not_lock_comb[i] && v_reg_fp_not_lock_comb[i] && v_csr_not_lock[i];                    
                        
            end
            // encode unit ===========================================================================
            assign v_goto_unit[i] = {1'b0,v_goto_mext[i],v_goto_float[i]|v_goto_csr[i],v_goto_float[i]|v_goto_csr[i],v_goto_custom[i]};    
            // reg lock cycle check ==================================================================
            assign v_reg_not_lock[i]    = (v_int_reg_rs1_rdy[i] || ~v_use_rs1_en[i]) &
                                          (v_int_reg_rs2_rdy[i] || ~v_use_rs2_en[i]) &
                                          (v_int_pre_allocate_vld[i] || ~v_dec_inst_rd_en[i]) ;

            assign v_reg_fp_not_lock[i] = (v_fp_reg_rs1_rdy[i] || ~v_use_rs1_fp_en[i]) &
                                          (v_fp_reg_rs2_rdy[i] || ~v_use_rs2_fp_en[i]) &
                                          (v_fp_reg_rs3_rdy[i] || ~v_use_rs3_fp_en[i]) &
                                          (v_fp_pre_allocate_vld[i] || ~v_dec_inst_fp_rd_en[i]);

            assign v_csr_not_lock[i] = ~csr_lock || (~v_goto_float[i] && ~ v_goto_csr[i]);
            // cycle check vld/rdy ===================================================================
            assign v_eu_vld_cycle_check[i] = v_dec_inst_vld[i] && v_reg_not_lock[i] && v_reg_fp_not_lock[i];

            assign v_eu_rdy_cycle_check[i] =    (v_goto_lsu[i]    & v_lsu_instruction_rdy[i] ) |
                                                (v_goto_alu[i]    & v_alu_instruction_rdy[i] ) |
                                                (v_goto_mext[i]   & mext_instruction_rdy     ) |
                                                (v_goto_float[i]  & float_instruction_rdy & csr_instruction_rdy ) |
                                                (v_goto_csr[i]    & csr_instruction_rdy   & float_instruction_rdy ) |
                                                (v_goto_custom[i] & custom_instruction_rdy   ) && 
                                                v_reg_not_lock[i] && v_reg_fp_not_lock[i];
            
            assign v_int_pre_allocate_zero[i] = (v_dec_inst_rd[i]==0)  ;

        end
    endgenerate


    `ifdef TOY_SIM


        logic [INST_DECODE_NUM-1:0] v_monitor_eu_hazard;
        logic [INST_DECODE_NUM-1:0] v_monitor_reg_lock;
        logic [INST_DECODE_NUM-1:0] v_monitor_phy_lock;

        generate
            for(genvar i=0;i<INST_DECODE_NUM;i=i+1)begin
            assign v_monitor_eu_hazard[i] =~(((v_goto_lsu[i]  & v_lsu_instruction_rdy[i] ) |
                                            (v_goto_alu[i]    & v_alu_instruction_rdy[i] ) |
                                            (v_goto_mext[i]   & mext_instruction_rdy     ) |
                                            (v_goto_float[i]  & float_instruction_rdy & csr_instruction_rdy     ) |
                                            (v_goto_csr[i]    & csr_instruction_rdy   & float_instruction_rdy   ) |
                                            (v_goto_custom[i] & custom_instruction_rdy   ) ) & ~v_unit_lock[i]);
            
            assign v_monitor_reg_lock[i] = ~((v_int_reg_rs1_rdy[i] || ~v_use_rs1_en[i]) & (v_int_reg_rs2_rdy[i] || ~v_use_rs2_en[i]) & (v_fp_reg_rs1_rdy[i] || ~v_use_rs1_fp_en[i]) &
                                          (v_fp_reg_rs2_rdy[i] || ~v_use_rs2_fp_en[i]) & (v_fp_reg_rs3_rdy[i] || ~v_use_rs3_fp_en[i]) & v_reg_not_lock_comb[i] &  v_reg_fp_not_lock_comb[i]);

            

            assign v_monitor_phy_lock[i] = ~((v_int_pre_allocate_vld[i] || ~v_dec_inst_rd_en[i]) &  (v_fp_pre_allocate_vld[i] || ~v_dec_inst_fp_rd_en[i]));
            
            end
        endgenerate

    `endif
endmodule

