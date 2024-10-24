

module toy_mext
    import toy_pack::*;
    (
        input  logic                      clk                 ,
        input  logic                      rst_n               ,

        input  logic                      instruction_vld     ,
        output logic                      instruction_rdy     ,
        input  logic [INST_WIDTH-1:0]     instruction_pld     ,
        input  logic [INST_IDX_WIDTH-1:0] instruction_idx     ,
        input  logic [PHY_REG_ID_WIDTH-1:0]inst_rd_idx        ,
        input  logic                      inst_rd_en          ,
        input  logic                      mext_c_ext          ,  
        input  logic [4:0]                arch_reg_index      , 
        input  logic [REG_WIDTH-1:0]      rs1_val             ,
        input  logic [REG_WIDTH-1:0]      rs2_val             ,
        input  logic [ADDR_WIDTH-1:0]     inst_pc             ,
        input  logic                      cancel_en           ,
        // commit 
        output commit_pkg                 mext_commit_pld     ,
        // reg access
        output logic [PHY_REG_ID_WIDTH-1:0]reg_index          ,
        output logic                      reg_wr_en           ,
        output logic [REG_WIDTH-1:0]      reg_val             ,
        output logic [INST_IDX_WIDTH-1:0] reg_inst_idx        ,
        output logic                      inst_commit_en      
    
    );
    
    logic        [2                 : 0]    funct3          ;
    logic signed [REG_WIDTH         : 0]    rs1_val_sign_ext;
    logic signed [REG_WIDTH         : 0]    rs2_val_sign_ext;
    logic signed [2*REG_WIDTH+1     : 0]    rs_mul_val      ;
    logic signed [REG_WIDTH-1       : 0]    rs_div_val      ;
    logic signed [REG_WIDTH-1       : 0]    rs_rem_val      ;
    logic signed [REG_WIDTH         : 0]    rs_div_temp     ;
    logic signed [REG_WIDTH         : 0]    rs_rem_temp     ;
    logic signed [REG_WIDTH         : 0]    rs2_val_div_sign_ext;
    logic        [MEXT_STAGES-1     : 0]    mext_en_d       ;
    mext_pkg                                mext_pld_d      [MEXT_STAGES-1:0];
    logic        [REG_WIDTH-1        :0]    rs1_val_d1;
    logic        [REG_WIDTH-1        :0]    rs2_val_d1;
    generate
        for(genvar i=0;i<MEXT_STAGES;i=i+1)begin
            if(i==0)begin
                assign mext_en_d[i]                     = instruction_vld & instruction_rdy;
                assign mext_pld_d[i].funct3             = funct3;
                assign mext_pld_d[i].reg_index          = inst_rd_idx;
                assign mext_pld_d[i].instruction_idx    = instruction_idx;
                assign mext_pld_d[i].inst_rd_en         = inst_rd_en;
                assign mext_pld_d[i].mext_c_ext         = mext_c_ext;
                assign mext_pld_d[i].arch_reg_index     = arch_reg_index;
                assign mext_pld_d[i].inst_pc            = inst_pc;
                assign mext_pld_d[i].instruction_pld    = instruction_pld;
                assign mext_pld_d[i].rs2_val            = rs2_val;
                assign mext_pld_d[i].rs1_val            = rs1_val;
            end
            else begin
                always_ff @(posedge clk or negedge rst_n) begin
                    if(~rst_n)begin
                        mext_en_d[i]            <= 0;
                        mext_pld_d[i]           <= {$bits(mext_pkg){1'b0}};
                    end
                    else if(cancel_en)begin
                        mext_en_d[i]            <= 0;
                    end
                    else begin
                        mext_en_d[i]            <= mext_en_d[i-1]         ;
                        mext_pld_d[i]           <= mext_pld_d[i-1]        ;
                    end
                end
            end
        end
    endgenerate

    assign rs2_val_d1 = mext_pld_d[1].rs2_val;
    assign rs1_val_d1 = mext_pld_d[1].rs1_val;

    assign funct3       = instruction_pld`INST_FIELD_FUNCT3 ;
    assign reg_index    = mext_pld_d[MEXT_STAGES-1].reg_index        ;
    // for warning todo
    assign rs2_val_div_sign_ext = |rs2_val_d1 ? rs2_val_sign_ext : {(REG_WIDTH+1){1'b1}};

    always_comb begin
        case(mext_pld_d[1].funct3)
            F3_MUL,F3_MULHU,F3_DIVU,F3_REMU    : begin
                rs1_val_sign_ext = $signed({1'b0,rs1_val_d1})                 ;
                rs2_val_sign_ext = $signed({1'b0,rs2_val_d1})                 ;
            end
            F3_MULH,F3_DIV,F3_REM   : begin
                rs1_val_sign_ext = $signed(rs1_val_d1)                        ;
                rs2_val_sign_ext = $signed(rs2_val_d1)                        ;
            end
            F3_MULHSU : begin
                rs1_val_sign_ext = $signed(rs1_val_d1)                        ;
                rs2_val_sign_ext = $signed({1'b0,rs2_val_d1})                 ;
            end
            default   : begin
                rs1_val_sign_ext = $signed({1'b0,rs1_val_d1})                 ;
                rs2_val_sign_ext = $signed({1'b0,rs2_val_d1})                 ;
            end
        endcase
    end

    DW_mult_pipe #(
        .a_width    (REG_WIDTH+1        ),
        .b_width    (REG_WIDTH+1        ),
        .num_stages (MEXT_STAGES-1      ),
        .rst_mode   (2                  )
        )
    metx_dw_mult(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .en         (|mext_en_d[MEXT_STAGES-1:1]),
        .tc         (1'b1               ),
        .a          (rs1_val_sign_ext   ),
        .b          (rs2_val_sign_ext   ),
        .product    (rs_mul_val         ));

    DW_div_pipe # (
        .a_width    (REG_WIDTH+1        ),
        .b_width    (REG_WIDTH+1        ),
        .tc_mode    (1'b1               ),
        .rem_mode   (1'b1               ),
        .num_stages (MEXT_STAGES-1       ),
        .rst_mode   (2                  ))
    metx_dw_div(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .en         (|mext_en_d[MEXT_STAGES-1:1]         ),
        .a          (rs1_val_sign_ext   ), 
        .b          (rs2_val_div_sign_ext), 
        .quotient   (rs_div_temp        ), 
        .remainder  (rs_rem_temp        ), 
        .divide_by_0(                   ));

    assign rs_div_val   = |mext_pld_d[MEXT_STAGES-1].rs2_val ? rs_div_temp[REG_WIDTH-1 : 0] : {REG_WIDTH{1'b1}} ; 
    assign rs_rem_val   = |mext_pld_d[MEXT_STAGES-1].rs2_val ? rs_rem_temp[REG_WIDTH-1 : 0] : mext_pld_d[MEXT_STAGES-1].rs1_val           ; 

    always_comb begin
        case(mext_pld_d[MEXT_STAGES-1].funct3)
            F3_MUL    : reg_val = rs_mul_val[REG_WIDTH-1:0]                 ;
            F3_MULH   : reg_val = rs_mul_val[2*REG_WIDTH-1:REG_WIDTH]       ;
            F3_MULHSU : reg_val = rs_mul_val[2*REG_WIDTH-1:REG_WIDTH]       ;
            F3_MULHU  : reg_val = rs_mul_val[2*REG_WIDTH-1:REG_WIDTH]       ;
            F3_DIV    : reg_val = rs_div_val[REG_WIDTH-1:0]                 ;
            F3_DIVU   : reg_val = rs_div_val[REG_WIDTH-1:0]                 ;
            F3_REM    : reg_val = rs_rem_val[REG_WIDTH-1:0]                 ;
            F3_REMU   : reg_val = rs_rem_val[REG_WIDTH-1:0]                 ;
            default   : reg_val = rs_rem_val[REG_WIDTH-1:0]                 ;
        endcase
    end

    assign inst_commit_en   = mext_en_d[MEXT_STAGES-1]   ;
    assign reg_inst_idx     = mext_pld_d[MEXT_STAGES-1].instruction_idx   ;
    assign reg_wr_en        = mext_en_d[MEXT_STAGES-1] & mext_pld_d[MEXT_STAGES-1].inst_rd_en  ;
    assign instruction_rdy  = 1'b1              ;

    //===================
    // commit 
    //===================

    assign mext_commit_pld.inst_id = mext_pld_d[MEXT_STAGES-1].instruction_idx;
    assign mext_commit_pld.inst_pc = mext_pld_d[MEXT_STAGES-1].inst_pc;
    assign mext_commit_pld.inst_nxt_pc = mext_pld_d[MEXT_STAGES-1].mext_c_ext ? mext_pld_d[MEXT_STAGES-1].inst_pc+2 : mext_pld_d[MEXT_STAGES-1].inst_pc + 4;
    assign mext_commit_pld.rd_en = mext_pld_d[MEXT_STAGES-1].inst_rd_en;
    assign mext_commit_pld.fp_rd_en = 1'b0;
    assign mext_commit_pld.arch_reg_index = mext_pld_d[MEXT_STAGES-1].arch_reg_index;
    assign mext_commit_pld.phy_reg_index = mext_pld_d[MEXT_STAGES-1].reg_index;
    assign mext_commit_pld.stq_commit_entry_en = 1'b0;
    // for bpu 
    assign mext_commit_pld.is_cext  = mext_pld_d[MEXT_STAGES-1].instruction_pld[1:0]!=2'b11;
    assign mext_commit_pld.inst_val = mext_pld_d[MEXT_STAGES-1].instruction_pld;
    assign mext_commit_pld.is_call  = 0;
    assign mext_commit_pld.is_ret   = 0;
    assign mext_commit_pld.FCSR_en  = 8'b0;
    assign mext_commit_pld.is_ind   = 0;
endmodule