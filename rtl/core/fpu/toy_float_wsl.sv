

module toy_float
    import toy_pack::*;
    (
        input  logic                      clk                 ,
        input  logic                      rst_n               ,

        input  logic                      instruction_vld     ,
        output logic                      instruction_rdy     ,
        input  eu_pkg                     instruction_pld     ,
        input  logic [31:0]               csr_FCSR            ,
        output logic                      csr_FFLAGS_en       ,
        output logic [4:0]                csr_FFLAGS          ,
        //commit 
        output commit_pkg                 fp_commit_pld       ,
        // reg access
        output logic [PHY_REG_ID_WIDTH-1:0]reg_index          ,
        output logic                      reg_wr_en           ,
        output logic [REG_WIDTH-1:0]      reg_val             ,
        output logic                      fp_reg_wr_en        ,
        output logic [INST_IDX_WIDTH-1:0] reg_inst_idx        ,
        output logic                      inst_commit_en      
    
    );

    //==============================
    // parameter
    //==============================
    localparam logic [31    :0]     CANONICAL_NAN       = 32'h7fc00000      ;
    localparam logic [31    :0]     ZERO_POSITIVE       = 32'h0             ;
    localparam logic [31    :0]     ZERO_NEGATIVE       = 32'h80000000      ;
    localparam logic [31    :0]     INFINITY_NEGATIVE   = 32'hff800000      ; 
    localparam logic [31    :0]     INFINITY_POSITIVE   = 32'h7f800000      ;
    
    //==============================
    // logic
    //==============================
    logic       [2              : 0]    funct3          ;
    logic       [4              : 0]    funct5          ;
    logic       [4              : 0]    cvt_sign        ;
    logic       [31             : 0]    flt2i_o         ;
    logic       [32             : 0]    flt2i_u_o       ;
    logic       [31             : 0]    i2flt_o         ;
    logic       [2              : 0]    fp_rnd          ;
    logic       [32             : 0]    rs1_val_sign    ;
    logic       [7              : 0]    flt2i_status    ;
    logic       [7              : 0]    i2flt_status    ;
    logic       [7              : 0]    flt2i_u_status  ;
    logic       [7              : 0]    float_status    ;
    logic       [31             : 0]    fadd_o          ;
    logic       [7              : 0]    fadd_status     ;
    logic       [31             : 0]    fmul_o          ;
    logic       [7              : 0]    fmul_status     ;
    logic       [31             : 0]    fdiv_o          ;
    logic       [7              : 0]    fdiv_status     ;
    logic       [31             : 0]    fsqrt_o         ;
    logic       [7              : 0]    fsqrt_status    ;
    logic       [31             : 0]    rs2_val_addsub  ;
    logic       [31             : 0]    rs1_val_addsub  ;
    logic       [4              : 0]    opcode          ;
    logic                               f_eq_flag       ;
    logic                               f_lt_flag       ;
    logic                               f_cmp_nv        ;
    logic       [31             : 0]    f_min           ;
    logic       [31             : 0]    f_max           ;
    logic       [7              : 0]    f_min_status    ;
    logic       [7              : 0]    f_max_status    ;
    logic                               snan_val1       ;
    logic                               snan_val2       ;
    logic                               nan_val1        ;
    logic                               nan_val2        ;
    logic       [9              : 0]    class_status    ;

    //==============================
    // pld data
    //==============================
    assign funct5       = instruction_pld.inst_pld`INST_FIELD_FUNCT5 ;
    assign funct3       = instruction_pld.inst_pld`INST_FIELD_FUNCT3 ;
    assign cvt_sign     = instruction_pld.inst_pld`INST_FIELD_RS2    ;
    assign opcode       = instruction_pld.inst_pld`INST_FIELD_OPCODE ;
    assign reg_index    = instruction_pld.inst_rd                       ;
    //===================
    // commit 
    //===================

    assign fp_commit_pld.inst_id = instruction_pld.inst_id;
    assign fp_commit_pld.inst_pc = instruction_pld.inst_pc;
    assign fp_commit_pld.inst_nxt_pc = instruction_pld.c_ext ? instruction_pld.inst_pc + 2 : instruction_pld.inst_pc + 4;
    assign fp_commit_pld.rd_en = instruction_pld.inst_rd_en;
    assign fp_commit_pld.fp_rd_en = instruction_pld.inst_fp_rd_en;
    assign fp_commit_pld.arch_reg_index = instruction_pld.arch_reg_index;
    assign fp_commit_pld.phy_reg_index = reg_index;
    assign fp_commit_pld.stq_commit_entry_en = 1'b0;

    // for bpu 
    assign fp_commit_pld.is_cext    = instruction_pld.c_ext;
    assign fp_commit_pld.inst_val   = instruction_pld.inst_pld;
    assign fp_commit_pld.is_call    = 0;
    assign fp_commit_pld.is_ret     = 0;
    assign fp_commit_pld.FCSR_en    = {3'b0,{5{csr_FFLAGS_en}}};
    assign fp_commit_pld.FCSR_data  = {3'b0,csr_FFLAGS};
    assign fp_commit_pld.is_ind     = 0;
    //==============================
    // nan flag
    //==============================
    assign snan_val1    = &instruction_pld.reg_rs1_val[30:23] & ~instruction_pld.reg_rs1_val[22] & |instruction_pld.reg_rs1_val[21:0]   ;
    assign snan_val2    = &instruction_pld.reg_rs2_val[30:23] & ~instruction_pld.reg_rs2_val[22] & |instruction_pld.reg_rs2_val[21:0]   ;
    assign nan_val1     = &instruction_pld.reg_rs1_val[30:23] & |instruction_pld.reg_rs1_val[22:0]                  ;
    assign nan_val2     = &instruction_pld.reg_rs2_val[30:23] & |instruction_pld.reg_rs2_val[22:0]                  ;
    //==============================
    // int2float  signed/unsigned
    //==============================
    assign rs1_val_sign =   ( (cvt_sign == FCVT_WU) && ( funct5 == FLOAT_CVT_SW) 
                            && (instruction_pld.reg_rs1_val[REG_WIDTH-1]) ) ? {1'b0,instruction_pld.reg_rs1_val} : {instruction_pld.reg_rs1_val[REG_WIDTH-1],instruction_pld.reg_rs1_val};

    //==============================
    // round type //todo 100 need tobe resolve
    //==============================
    always_comb begin 
        if(instruction_vld && instruction_rdy)begin
            if (instruction_pld.inst_pld`INST_FILED_F_RM == FRND_DYN)begin
                if ((csr_FCSR[7:5]==FRND_DYN)||(csr_FCSR[7:5]==FRND_RES0)||(csr_FCSR[7:5]==FRND_RES1)||(csr_FCSR[7:5]==FRND_RMM))begin
                    fp_rnd = FRND_RNE;
                end
                else begin
                    fp_rnd = csr_FCSR[7:5];
                end
            end
            else if((instruction_pld.inst_pld`INST_FILED_F_RM==FRND_RES0)||(instruction_pld.inst_pld`INST_FILED_F_RM==FRND_RES1)||(instruction_pld.inst_pld`INST_FILED_F_RM==FRND_RMM))begin
                fp_rnd = FRND_RNE;
            end
            else if(instruction_pld.inst_pld`INST_FILED_F_RM==FRND_RDN)begin
                fp_rnd = FRND_RUP; //just for dw
            end
            else if(instruction_pld.inst_pld`INST_FILED_F_RM==FRND_RUP)begin
                fp_rnd = FRND_RDN; //just for dw
            end
            else begin
                fp_rnd = instruction_pld.inst_pld`INST_FILED_F_RM;
            end
        end
        else begin
            fp_rnd = FRND_RNE;
        end
    end

    //==============================
    // DW float2 signed int
    //==============================
    DW_fp_flt2i #(
        .ieee_compliance(1          )
        ) u_fp_flt2i(
            .a      (instruction_pld.reg_rs1_val        ),
            .rnd    (fp_rnd         ),
            .z      (flt2i_o        ),
            .status (flt2i_status   )
        );
    //==============================
    // DW float2 unsigned int //todo merge
    //==============================
    DW_fp_flt2i #(
        .isize(33                   ),
        .ieee_compliance(1          )
        ) u_fp_u_flt2i(
            .a      (instruction_pld.reg_rs1_val        ),
            .rnd    (fp_rnd         ),
            .z      (flt2i_u_o      ),
            .status (flt2i_u_status )
        );
    //==============================
    // DW int2float
    //==============================
    DW_fp_i2flt #(
        .isize  (33                 ),
        .isign  (1                  )
        ) u_fp_i2flt(
            .a      (rs1_val_sign   ),
            .rnd    (fp_rnd         ),
            .z      (i2flt_o        ),
            .status (i2flt_status   )
        );
    //==============================
    // DW add / sub /madd
    //==============================
    // DW_fp_add_DG #(
    //     .ieee_compliance(3          )
    //     )u_fp_add ( 
    //         .a      (rs1_val_addsub ),
    //         .b      (rs2_val_addsub ), 
    //         .rnd    (fp_rnd         ), 
    //         .DG_ctrl(instruction_vld), 
    //         .z      (fadd_o         ), 
    //         .status (fadd_status    ) 
    //     );
    DW_fp_add #(
        .ieee_compliance(1          )
        )u_fp_add ( 
            .a      (rs1_val_addsub ),
            .b      (rs2_val_addsub ), 
            .rnd    (fp_rnd         ), 
            .z      (fadd_o         ), 
            .status (fadd_status    ) 
        );
    //==============================
    // DW mult
    //==============================
    // DW_fp_mult_DG #(
    //     .ieee_compliance(3          ),
    //     .en_ubr_flag(1              )
    //     )u_fp_mult ( 
    //         .a      (instruction_pld.reg_rs1_val        ),
    //         .b      (instruction_pld.reg_rs2_val        ), 
    //         .rnd    (fp_rnd         ), 
    //         .DG_ctrl(instruction_vld), 
    //         .z      (fmul_o         ), 
    //         .status (fmul_status    ) 
    //     );
    DW_fp_mult #(
        .ieee_compliance(1          ),
        .en_ubr_flag(1              )
        )u_fp_mult ( 
            .a      (instruction_pld.reg_rs1_val        ),
            .b      (instruction_pld.reg_rs2_val        ), 
            .rnd    (fp_rnd         ), 
            .z      (fmul_o         ), 
            .status (fmul_status    ) 
        );
    //==============================
    // DW div
    //==============================
    // DW_fp_div_DG #(
    //     .ieee_compliance(3          ),
    //     .en_ubr_flag(1              )
    //     )u_fp_div ( 
    //         .a      (instruction_pld.reg_rs1_val        ),
    //         .b      (instruction_pld.reg_rs2_val        ), 
    //         .rnd    (fp_rnd         ), 
    //         .DG_ctrl(instruction_vld), 
    //         .z      (fdiv_o         ), 
    //         .status (fdiv_status    ) 
    //     );
    DW_fp_div #(
        .ieee_compliance(1          ),
        .en_ubr_flag(1              )
        )u_fp_div ( 
            .a      (instruction_pld.reg_rs1_val        ),
            .b      (instruction_pld.reg_rs2_val        ), 
            .rnd    (fp_rnd         ), 
            .z      (fdiv_o         ), 
            .status (fdiv_status    ) 
        );
    //==============================
    // DW sqrt
    //==============================
    DW_fp_sqrt #(
        .ieee_compliance(1          )
    )u_fp_sqrt ( 
            .a      (instruction_pld.reg_rs1_val        ),
            .rnd    (fp_rnd         ), 
            .z      (fsqrt_o        ), 
            .status (fsqrt_status   ) 
        );
    //==============================
    // DW compare
    //==============================
    // DW_fp_cmp_DG #(
    //     .ieee_compliance(1          )
    //     )u_fp_cmp ( 
    //         .a      (instruction_pld.reg_rs1_val        ), 
    //         .b      (instruction_pld.reg_rs2_val        ), 
    //         .zctr   (1'b0           ), 
    //         .DG_ctrl(instruction_vld), 
    //         .aeqb   (f_eq_flag      ), 
    //         .altb   (f_lt_flag      ), 
    //         .agtb   (               ),
    //         .unordered(f_cmp_nv     ),
    //         .z0     (f_min          ), 
    //         .z1     (f_max          ), 
    //         .status0(f_min_status   ), 
    //         .status1(f_max_status   ) 
    //         );
    DW_fp_cmp #(
        .ieee_compliance(1          )
        )u_fp_cmp ( 
            .a      (instruction_pld.reg_rs1_val        ), 
            .b      (instruction_pld.reg_rs2_val        ), 
            .zctr   (1'b0           ), 
            .aeqb   (f_eq_flag      ), 
            .altb   (f_lt_flag      ), 
            .agtb   (               ),
            .unordered(f_cmp_nv     ),
            .z0     (f_min          ), 
            .z1     (f_max          ), 
            .status0(f_min_status   ), 
            .status1(f_max_status   ) 
            );

    // ===================================================================================
    // class
    // ===================================================================================


    //0 =======-inf ==============================================================
    assign class_status[0] = instruction_pld.reg_rs1_val==INFINITY_NEGATIVE;
    //1 ======= negative normal ==================================================
    assign class_status[1] = instruction_pld.reg_rs1_val[31] && ~&instruction_pld.reg_rs1_val[30:23] && |instruction_pld.reg_rs1_val[30:23];
    //2 ======= negative subnormal ===============================================
    assign class_status[2] = instruction_pld.reg_rs1_val[31] && ~|instruction_pld.reg_rs1_val[30:23] && |instruction_pld.reg_rs1_val[22:0];
    //3 ======= -0 ===============================================================
    assign class_status[3] = instruction_pld.reg_rs1_val == ZERO_NEGATIVE;
    //4 ======= +0 ===============================================================
    assign class_status[4] = instruction_pld.reg_rs1_val == ZERO_POSITIVE;
    //5 ======= positive subnormal ===============================================
    assign class_status[5] = ~instruction_pld.reg_rs1_val[31] && ~|instruction_pld.reg_rs1_val[30:23] && |instruction_pld.reg_rs1_val[22:0];
    //6 ======= positive normal ==================================================
    assign class_status[6] = ~instruction_pld.reg_rs1_val[31] && ~&instruction_pld.reg_rs1_val[30:23] && |instruction_pld.reg_rs1_val[30:23];
    //7 ======= +inf =============================================================
    assign class_status[7] = instruction_pld.reg_rs1_val == INFINITY_POSITIVE;
    //8 ======= snan =============================================================
    assign class_status[8] = &instruction_pld.reg_rs1_val[30:23] & ~instruction_pld.reg_rs1_val[22] & |instruction_pld.reg_rs1_val[21:0];
    //9 ======= qnan =============================================================
    assign class_status[9] = &instruction_pld.reg_rs1_val[30:23] & instruction_pld.reg_rs1_val[22];

    //==============================
    // add /sub /madd  input for add
    //==============================
    always_comb begin 
        case (opcode)
            OPC_FMADD:begin
                rs1_val_addsub = fmul_o;
                rs2_val_addsub = instruction_pld.reg_rs3_val;
            end
            OPC_FMSUB:begin
                rs1_val_addsub = fmul_o;
                rs2_val_addsub = {~instruction_pld.reg_rs3_val[31],instruction_pld.reg_rs3_val[30:0]};
            end
            OPC_FNMADD:begin
                rs1_val_addsub = {~fmul_o[31],fmul_o[30:0]};
                rs2_val_addsub = {~instruction_pld.reg_rs3_val[31],instruction_pld.reg_rs3_val[30:0]};
            end
            OPC_FNMSUB: begin
                rs1_val_addsub = {~fmul_o[31],fmul_o[30:0]};
                rs2_val_addsub = instruction_pld.reg_rs3_val;
            end
            default: begin
                rs1_val_addsub = instruction_pld.reg_rs1_val;
                if(funct5==FLOAT_ADD)   rs2_val_addsub = instruction_pld.reg_rs2_val;
                else                    rs2_val_addsub = {~instruction_pld.reg_rs2_val[31],instruction_pld.reg_rs2_val[30:0]};
            end
        endcase
    end
    //==============================
    // float status ,update csr
    //==============================
    always_comb begin 
        if(opcode == OPC_OP_FP)
            case (funct5)
                FLOAT_CVT_SW: float_status = i2flt_status;
                FLOAT_CVT_WS: begin
                    if(cvt_sign == FCVT_WU)begin
                        float_status = flt2i_u_status;
                    end
                    else begin
                        float_status = flt2i_status;
                    end
                end
                FLOAT_ADD,FLOAT_SUB     : float_status = fadd_status;   
                FLOAT_MUL               : float_status = fmul_status;   
                FLOAT_DIV               : float_status = fdiv_status;   
                FLOAT_SQRT              : float_status = fsqrt_status;   
                FLOAT_CMP               : float_status = {7'b0,f_cmp_nv};
                default: float_status = i2flt_status;
            endcase
        else begin
            float_status = fadd_status;
        end
    end
    assign csr_FFLAGS_en = instruction_vld;
    always_comb begin
        csr_FFLAGS = csr_FCSR[4:0];
        if(instruction_vld)begin
            if(opcode==OPC_OP_FP)begin
                case (funct5)
                    FLOAT_CVT_SW: csr_FFLAGS[4] = float_status[5];
                    FLOAT_CVT_WS: begin
                        if((cvt_sign == FCVT_WU) && (instruction_pld.reg_rs1_val[REG_WIDTH-1]))begin 
                            csr_FFLAGS[0] = float_status[0] && float_status[5];
                            csr_FFLAGS[4] = ~(float_status[0] && float_status[5]);
                        end
                        else begin
                            csr_FFLAGS[0] = ~(float_status[6] | float_status[3]) & float_status[5];
                            csr_FFLAGS[4] = float_status[6] | float_status[3] ;
                        end
                    end
                    FLOAT_CMP   : begin
                        if (funct3 == FCMP_FEQ) csr_FFLAGS[4] = float_status[0] & (snan_val1 | snan_val2);
                        else                    csr_FFLAGS[4] = float_status[0];
                    end
                    FLOAT_MINMAX : csr_FFLAGS[4] = (snan_val1 | snan_val2);
                    FLOAT_ADD,FLOAT_SUB,FLOAT_MUL:begin
                        csr_FFLAGS[0] = float_status[5] ;
                        csr_FFLAGS[4] = float_status[2] ;
                    end
                    FLOAT_DIV : begin
                        csr_FFLAGS[3] =  (instruction_pld.reg_rs2_val == ZERO_POSITIVE)|(instruction_pld.reg_rs2_val==ZERO_NEGATIVE);
                        csr_FFLAGS[0] = float_status[5] ;
                        csr_FFLAGS[4] = float_status[2] ;
                    end
                    FLOAT_SQRT : begin
                        csr_FFLAGS[0] = float_status[5] ;
                        csr_FFLAGS[4] = float_status[2] ;
                    end
                    default: csr_FFLAGS = csr_FCSR[4:0];
                endcase
            end
            else begin //fmadd
                csr_FFLAGS[0] = float_status[5] ;
                csr_FFLAGS[4] = float_status[2] ;
            end
        end
    end


    //==============================
    // output reg_val
    //==============================

    always_comb begin
    case (opcode)
        OPC_FMADD,OPC_FMSUB,OPC_FNMADD,OPC_FNMSUB : reg_val = fadd_o;
        OPC_OP_FP:begin
            case(funct5)
                FLOAT_CMP           : begin
                    case (funct3)
                        FCMP_FEQ    :           reg_val = {31'b0,f_eq_flag};
                        FCMP_FLT    :           reg_val = {31'b0,f_lt_flag};
                        FCMP_FLE    :           reg_val = {31'b0,f_eq_flag|f_lt_flag};
                        default     :           reg_val = 32'b0;
                    endcase
                end
                FLOAT_MINMAX        : begin
                    if(nan_val1 && nan_val2)    reg_val = CANONICAL_NAN;
                    else if (nan_val1)          reg_val = instruction_pld.reg_rs2_val;
                    else if (nan_val2)          reg_val = instruction_pld.reg_rs1_val;
                    else begin
                        case (funct3)
                            FMINMAX_MIN :       begin
                                if(f_min_status[0] && f_max_status[0])  reg_val = ZERO_NEGATIVE;
                                else                                    reg_val = f_min;
                            end 
                            FMINMAX_MAX :       begin
                                if(f_min_status[0] && f_max_status[0])  reg_val = ZERO_POSITIVE;
                                else                                    reg_val = f_max;
                            end 
                            default     :       reg_val = 32'b0;
                        endcase
                    end
                end
                FLOAT_ADD,FLOAT_SUB :       reg_val = fadd_o;
                FLOAT_DIV           :       reg_val = fdiv_o;
                FLOAT_MUL           :       reg_val = fmul_o;
                FLOAT_SQRT          : begin
                    if(instruction_pld.reg_rs1_val[31])begin
                        reg_val = CANONICAL_NAN;
                    end
                    else begin
                        reg_val = fsqrt_o;
                    end
                end
                FLOAT_SGNJ          : begin
                    case (funct3)
                        FSGNJ_SGNJ  :       reg_val = {instruction_pld.reg_rs2_val[REG_WIDTH-1] , instruction_pld.reg_rs1_val[REG_WIDTH-2:0] }  ;
                        FSGNJ_SGNJ_N:       reg_val = {~instruction_pld.reg_rs2_val[REG_WIDTH-1], instruction_pld.reg_rs1_val[REG_WIDTH-2:0] }  ;
                        FSGNJ_SGNJ_X:       reg_val = {instruction_pld.reg_rs2_val[REG_WIDTH-1]^instruction_pld.reg_rs1_val[REG_WIDTH-1], instruction_pld.reg_rs1_val[REG_WIDTH-2:0] };
                        default:            reg_val = 32'b0                                             ;
                    endcase
                end
                FLOAT_MVWX          :       reg_val = instruction_pld.reg_rs1_val[REG_WIDTH-1:0]                            ;
                FLOAT_MVXW_CLASS    : begin 
                    if(funct3 == FMVCL_MV)  reg_val = instruction_pld.reg_rs1_val[REG_WIDTH-1:0]                            ;
                    else                    reg_val = {22'b0,class_status}                              ;
                end
                FLOAT_CVT_SW        :       reg_val = i2flt_o                                           ;
                FLOAT_CVT_WS        : begin
                    if(cvt_sign == FCVT_WU) begin
                        if(instruction_pld.reg_rs1_val[REG_WIDTH-1])begin 
                            if(nan_val1)begin
                                reg_val = 32'hffffffff                                                  ;
                            end
                            else begin
                                reg_val = 32'b0                                                         ;
                            end
                        end
                        else if(&instruction_pld.reg_rs1_val[30:23])begin
                            reg_val = 32'hffffffff;
                        end
                        else begin
                            reg_val = flt2i_u_o[REG_WIDTH-1 : 0];
                        end
                    end
                    else begin
                        if(&instruction_pld.reg_rs1_val[30:23])begin
                            if(instruction_pld.reg_rs1_val[31] & ~|instruction_pld.reg_rs1_val[22:0])begin
                                reg_val = ZERO_NEGATIVE;
                            end
                            else begin
                                reg_val = 32'h7fffffff;
                            end
                        end
                        else begin
                            reg_val = flt2i_o    ;
                        end
                    end
                end
                default             :       reg_val = 32'b0                                   ;
            endcase
        end
        default                     :       reg_val = 32'b0                                   ;
    endcase
    end

    //==============================
    // output int wr / float wr
    //==============================
    always_comb begin
        case(funct5)
            FLOAT_MVXW_CLASS    :       reg_wr_en = instruction_vld & instruction_pld.inst_rd_en  ;
            FLOAT_CVT_WS        :       reg_wr_en = instruction_vld & instruction_pld.inst_rd_en  ;
            FLOAT_CMP           :       reg_wr_en = instruction_vld & instruction_pld.inst_rd_en  ;
            default             :       reg_wr_en = 1'b0                          ;
        endcase
    end

    always_comb begin
        case(funct5)
            FLOAT_MVXW_CLASS    :       fp_reg_wr_en = 1'b0  ;
            FLOAT_CVT_WS        :       fp_reg_wr_en = 1'b0  ;
            FLOAT_CMP           :       fp_reg_wr_en = 1'b0  ;
            default             :       fp_reg_wr_en = instruction_vld & instruction_pld.inst_fp_rd_en;
        endcase
    end

    assign inst_commit_en   = instruction_vld   ;
    assign reg_inst_idx     = instruction_pld.inst_id   ;
    assign instruction_rdy  = 1'b1              ;



endmodule