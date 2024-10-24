module toy_ldq 
    import toy_pack::*;
(
    input  logic                             clk                        ,
    input  logic                             rst_n                      ,

    input  logic  [1                    :0]  s_load_vld                 ,
    input  ldu_pkg                           s_load_pld         [1:0]   ,
    input  logic  [1                    :0]  v_ldq_rdy                  ,

    input  logic [1                     :0]  v_ldq_ack_en               ,
    input  logic [1                     :0]  v_ldq_ack_flag             ,
    input  ldq_ack_pkg                       v_ldq_ack_pld      [1:0]   ,

    output logic                             ldq_credit_en              ,
    output logic [3                     :0]  ldq_credit_num             ,     

    output mem_req_pkg                       s_mem_req_pld              ,
    output logic                             s_mem_req_vld              ,
    input  logic                             s_mem_req_rdy              ,

    input  mem_ack_pkg                       m_mem_ack_pld              ,
    input  logic                             m_mem_ack_vld              ,
    output logic                             m_mem_ack_rdy              ,
    
    input  logic  [2                    :0]  branch_id                  , 

    output logic [PHY_REG_ID_WIDTH-1    :0]  v_reg_index        [2:0]   ,
    output logic [2                     :0]  reg_wr_en                  ,
    output logic [2                     :0]  fp_reg_wr_en               ,
    output logic [REG_WIDTH-1           :0]  reg_val            [2:0]   ,

    input  logic                             cancel_en                  ,
    output logic [2                     :0]  v_ldq_commit_en            ,
    output commit_pkg                        v_ldq_commit_pld   [2:0]   
);


    //==========================
    // parameter
    //==========================
    localparam integer unsigned DEPTH_WIDTH = $clog2(LDU_DEPTH);
    //==========================
    // logic
    //==========================
    ldq_pkg                 v_entry_pld       [LDU_DEPTH-1:0];
    logic                   mem_not_req_en              ; 
    logic [LDU_DEPTH-1  :0] v_mem_not_req               ;
    logic                   mem_req_bypass              ;
    logic [1            :0] wr_en                       ;
    logic                   rd_en                       ;
    logic [1            :0] v_ld_mem_req_en             ;
    logic [LDU_DEPTH-1  :0] mask_en                     ;
    logic [DEPTH_WIDTH-1:0] mem_not_req_entry_id        ;
    logic [DEPTH_WIDTH-1:0] wr_ptr                      ;
    logic [DEPTH_WIDTH-1:0] rd_ptr                      ;
    logic [LDU_DEPTH-1  :0] v_entry_stq_flag            ;
    logic [LDU_DEPTH-1  :0] v_entry_mem_req             ;
    logic [LDU_DEPTH-1  :0] v_entry_mem_ack             ;
    logic [LDU_DEPTH-1  :0] v_stq_ack_flag              ;
    logic [LDU_DEPTH-1  :0] v_entry_en                  ;
    logic [DATA_WIDTH-1 :0] shifted_rd_data     [2:0]   ;
    logic [REG_WIDTH-1  :0] reg_val_funct3      [2:0]   ;
    logic [DEPTH_WIDTH-1:0] v_ld_mem_req_bin    [1:0]   ;
    logic [LDU_DEPTH-1  :0] v_ld_mem_not_req    [1:0]        ;
    logic [LDU_DEPTH-1  :0] v_ld_mem_not_req_revert [1:0]    ;
    //==========================
    // commit 
    //==========================
    assign v_ldq_commit_en = reg_wr_en | fp_reg_wr_en;

    assign v_ldq_commit_pld[0].inst_id = v_ldq_ack_pld[0].inst_id;
    assign v_ldq_commit_pld[0].inst_pc = v_ldq_ack_pld[0].inst_pc;
    assign v_ldq_commit_pld[0].arch_reg_index = v_ldq_ack_pld[0].arch_reg_index;
    assign v_ldq_commit_pld[0].phy_reg_index = v_ldq_ack_pld[0].phy_reg_index;
    assign v_ldq_commit_pld[0].rd_en = v_ldq_ack_pld[0].rd_en;
    assign v_ldq_commit_pld[0].fp_rd_en = v_ldq_ack_pld[0].fp_rd_en;
    assign v_ldq_commit_pld[0].inst_nxt_pc = v_ldq_ack_pld[0].c_ext ? v_ldq_ack_pld[0].inst_pc+2 : v_ldq_ack_pld[0].inst_pc+4;
    assign v_ldq_commit_pld[0].stq_commit_entry_en = 1'b0;
    assign v_ldq_commit_pld[0].inst_val = 0;
    assign v_ldq_commit_pld[0].is_cext  = v_ldq_ack_pld[0].c_ext;
    assign v_ldq_commit_pld[0].is_call  = 0;
    assign v_ldq_commit_pld[0].is_ret   = 0;
    assign v_ldq_commit_pld[0].FCSR_en  = 8'b0;

    assign v_ldq_commit_pld[1].inst_id = v_ldq_ack_pld[1].inst_id;
    assign v_ldq_commit_pld[1].inst_pc = v_ldq_ack_pld[1].inst_pc;
    assign v_ldq_commit_pld[1].arch_reg_index = v_ldq_ack_pld[1].arch_reg_index;
    assign v_ldq_commit_pld[1].phy_reg_index = v_ldq_ack_pld[1].phy_reg_index;
    assign v_ldq_commit_pld[1].rd_en = v_ldq_ack_pld[1].rd_en;
    assign v_ldq_commit_pld[1].fp_rd_en = v_ldq_ack_pld[1].fp_rd_en;
    assign v_ldq_commit_pld[1].inst_nxt_pc = v_ldq_ack_pld[1].c_ext ? v_ldq_ack_pld[1].inst_pc+2 : v_ldq_ack_pld[1].inst_pc+4;
    assign v_ldq_commit_pld[1].stq_commit_entry_en = 1'b0;
    assign v_ldq_commit_pld[1].inst_val = 0;
    assign v_ldq_commit_pld[1].is_cext  = v_ldq_ack_pld[1].c_ext;
    assign v_ldq_commit_pld[1].is_call  = 0;
    assign v_ldq_commit_pld[1].is_ret   = 0;
    assign v_ldq_commit_pld[1].FCSR_en  = 8'b0;

    assign v_ldq_commit_pld[2].inst_id = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_id;
    assign v_ldq_commit_pld[2].inst_pc = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_pc;
    assign v_ldq_commit_pld[2].arch_reg_index = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].arch_reg_index;
    assign v_ldq_commit_pld[2].phy_reg_index = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_rd;   
    assign v_ldq_commit_pld[2].rd_en = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_rd_en;
    assign v_ldq_commit_pld[2].fp_rd_en = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_fp_rd_en;
    assign v_ldq_commit_pld[2].inst_nxt_pc = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].c_ext ? v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_pc+2 : v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_pc+4;
    assign v_ldq_commit_pld[2].stq_commit_entry_en = 1'b0;
    assign v_ldq_commit_pld[2].inst_val = 0;
    assign v_ldq_commit_pld[2].is_cext  = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].c_ext;
    assign v_ldq_commit_pld[2].is_call  = 0;
    assign v_ldq_commit_pld[2].is_ret   = 0;
    assign v_ldq_commit_pld[2].FCSR_en  = 8'b0;
    //==========================
    // WB
    //==========================
    assign v_reg_index[0]   = s_load_pld[0].inst_rd;
    assign reg_wr_en[0]     = v_ldq_ack_flag[0] && s_load_pld[0].inst_rd_en;
    assign fp_reg_wr_en[0]  = v_ldq_ack_flag[0] && s_load_pld[0].inst_fp_rd_en;
    assign reg_val[0]       = reg_val_funct3[0][31:0];

    assign v_reg_index[1]   = s_load_pld[1].inst_rd;
    assign reg_wr_en[1]     = v_ldq_ack_flag[1] && s_load_pld[1].inst_rd_en;
    assign fp_reg_wr_en[1]  = v_ldq_ack_flag[1] && s_load_pld[1].inst_fp_rd_en;
    assign reg_val[1]       = reg_val_funct3[1][31:0];

    assign v_reg_index[2]   = v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_rd;
    assign reg_wr_en[2]     = m_mem_ack_vld & ~v_stq_ack_flag[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])]&&v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_rd_en;
    assign fp_reg_wr_en[2]  = m_mem_ack_vld & ~v_stq_ack_flag[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])]&&v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].inst_fp_rd_en;
    assign reg_val[2]       = reg_val_funct3[2][31:0];

    assign shifted_rd_data[0]  = v_ldq_ack_pld[0].mem_req_data  ;
    assign shifted_rd_data[1]  = v_ldq_ack_pld[1].mem_req_data  ;
    assign shifted_rd_data[2]  = (m_mem_ack_pld.mem_ack_data >> v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].mem_req_addr[4:0]*8)  ;



    generate
        for(genvar i=0;i<2;i=i+1)begin
            always_comb begin
                case(s_load_pld[i].funct3)
                    F3_LB       :   reg_val_funct3[i] = {{24{shifted_rd_data[i][7]}}   ,   shifted_rd_data[i][7:0]    };
                    F3_LBU      :   reg_val_funct3[i] = {24'b0                         ,   shifted_rd_data[i][7:0]    };
                    F3_LH       :   reg_val_funct3[i] = {{16{shifted_rd_data[i][15]}}  ,   shifted_rd_data[i][15:0]   };
                    F3_LHU      :   reg_val_funct3[i] = {16'b0                         ,   shifted_rd_data[i][15:0]   };
                    F3_LW       :   reg_val_funct3[i] = shifted_rd_data[i][31:0];
                    default     :   reg_val_funct3[i] = shifted_rd_data[i][31:0];
                endcase
            end
        end
    endgenerate

    always_comb begin
        case(v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])].funct3)
            F3_LB       :   reg_val_funct3[2] = {{24{shifted_rd_data[2][7]}}   ,   shifted_rd_data[2][7:0]    };
            F3_LBU      :   reg_val_funct3[2] = {24'b0                         ,   shifted_rd_data[2][7:0]    };
            F3_LH       :   reg_val_funct3[2] = {{16{shifted_rd_data[2][15]}}  ,   shifted_rd_data[2][15:0]   };
            F3_LHU      :   reg_val_funct3[2] = {16'b0                         ,   shifted_rd_data[2][15:0]   };
            F3_LW       :   reg_val_funct3[2] = shifted_rd_data[2][31:0];
            default     :   reg_val_funct3[2] = shifted_rd_data[2][31:0];
        endcase
    end




    assign m_mem_ack_rdy = 1'b1;

    //==========================
    // credit
    //==========================
    assign ldq_credit_en = rd_en;
    assign ldq_credit_num = 2'd1;
    
    //==========================
    // rd ptr
    //==========================
    assign rd_en = v_entry_en[rd_ptr] && ((v_entry_mem_req[rd_ptr] && v_entry_mem_ack[rd_ptr]) || v_entry_stq_flag[rd_ptr]);
    // assign rd_en[1] = v_entry_en[DEPTH_WIDTH'(rd_ptr+1)] && ((v_entry_mem_req[DEPTH_WIDTH'(rd_ptr+1)] && v_entry_mem_ack[DEPTH_WIDTH'(rd_ptr+1)]) || v_entry_stq_flag[DEPTH_WIDTH'(rd_ptr+1)]);


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            rd_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(cancel_en)begin
            rd_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(rd_en)begin
            rd_ptr <= rd_ptr + 1'b1;                                
        end
    end




    //==========================
    // bypass 
    //==========================

    assign wr_en[0] = v_ldq_rdy[0] & s_load_vld[0];
    assign wr_en[1] = v_ldq_rdy[1] & s_load_vld[1];

    assign v_mem_not_req = v_entry_en & ~v_entry_mem_req & ~v_stq_ack_flag;
    assign v_ld_mem_not_req[0] = v_mem_not_req & ~mask_en;
    assign v_ld_mem_not_req[1] = v_mem_not_req & mask_en;
    generate

        for(genvar j=0;j<2;j=j+1)begin
            cmn_lead_one #(
                .ENTRY_NUM      (STU_DEPTH                  )
                // .REQ_NUM        (1                          )
            ) u_hazard_ldone(
                .v_entry_vld    (v_ld_mem_not_req[j]        ),
                .v_free_idx_oh  (                           ),
                .v_free_idx_bin (v_ld_mem_req_bin[j]        ),
                .v_free_vld     (v_ld_mem_req_en[j]         )
            );
        end

        for(genvar i=0;i<STU_DEPTH;i=i+1)begin
            assign mask_en[i] = (i<=(DEPTH_WIDTH'(wr_ptr-1)));
            // assign v_ld_mem_not_req_revert[0][i] = v_ld_mem_not_req[0][STU_DEPTH-1-i];
            // assign v_ld_mem_not_req_revert[1][i] = v_ld_mem_not_req[1][STU_DEPTH-1-i];
        end
    endgenerate

    assign mem_not_req_en = v_ld_mem_req_en[0] | v_ld_mem_req_en[1];
    assign mem_not_req_entry_id = v_ld_mem_req_en[0] ? v_ld_mem_req_bin[0] : v_ld_mem_req_bin[1];

    assign s_mem_req_vld = mem_not_req_en ? 1'b1:(wr_en[0]&~v_ldq_ack_en[0]);
    assign s_mem_req_pld.mem_req_addr = mem_not_req_en ? v_entry_pld[mem_not_req_entry_id].mem_req_addr : s_load_pld[0].mem_req_addr;
    assign s_mem_req_pld.mem_req_sideband[DEPTH_WIDTH-1:0] = mem_not_req_en ? mem_not_req_entry_id : wr_ptr;
    assign s_mem_req_pld.mem_req_sideband[9:7] = branch_id;

    assign s_mem_req_pld.mem_req_strb = mem_not_req_en ? v_entry_pld[mem_not_req_entry_id].mem_req_strb : s_load_pld[0].mem_req_strb;
    assign s_mem_req_pld.mem_req_opcode = TOY_BUS_READ;
    assign s_mem_req_pld.mem_req_data = 0;
    assign mem_req_bypass = ~|v_mem_not_req & s_mem_req_vld & s_mem_req_rdy;

    //==========================
    // wr ptr
    //==========================
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            wr_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(cancel_en)begin
            wr_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(wr_en[1])begin
            wr_ptr <= wr_ptr + 2'd2;
        end
        else if(wr_en[0])begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    //==========================
    // mem
    //==========================

    generate
        for(genvar i=0;i<STU_DEPTH;i=i+1)begin
            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    v_entry_pld[i] <= {$bits(ldq_pkg){1'b0}};
                end
                else if((wr_en[0])&&(i==wr_ptr))begin
                    v_entry_pld[i].mem_req_addr <= s_load_pld[0].mem_req_addr;
                    v_entry_pld[i].mem_req_strb <= s_load_pld[0].mem_req_strb;
                    v_entry_pld[i].inst_rd      <= s_load_pld[0].inst_rd;
                    v_entry_pld[i].inst_rd_en   <= s_load_pld[0].inst_rd_en;
                    v_entry_pld[i].inst_fp_rd_en<= s_load_pld[0].inst_fp_rd_en;
                    v_entry_pld[i].funct3       <= s_load_pld[0].funct3;
                    v_entry_pld[i].inst_pc      <= s_load_pld[0].inst_pc;
                    v_entry_pld[i].inst_id      <= s_load_pld[0].inst_id;
                    v_entry_pld[i].arch_reg_index<= s_load_pld[0].arch_reg_index;
                    v_entry_pld[i].c_ext        <= s_load_pld[0].c_ext;
                end
                else if((wr_en[1])&&(i==(DEPTH_WIDTH'(wr_ptr+1))))begin
                    v_entry_pld[i].mem_req_addr <= s_load_pld[1].mem_req_addr;
                    v_entry_pld[i].mem_req_strb <= s_load_pld[1].mem_req_strb;
                    v_entry_pld[i].inst_rd      <= s_load_pld[1].inst_rd;
                    v_entry_pld[i].inst_rd_en   <= s_load_pld[1].inst_rd_en;
                    v_entry_pld[i].funct3       <= s_load_pld[1].funct3;
                    v_entry_pld[i].inst_pc      <= s_load_pld[1].inst_pc;
                    v_entry_pld[i].inst_id      <= s_load_pld[1].inst_id;
                    v_entry_pld[i].inst_fp_rd_en<= s_load_pld[1].inst_fp_rd_en;
                    v_entry_pld[i].arch_reg_index<= s_load_pld[1].arch_reg_index;
                    v_entry_pld[i].c_ext        <= s_load_pld[1].c_ext;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_stq_flag[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_entry_stq_flag[i] <= 1'b0;
                end
                else if ((v_ldq_ack_flag[0]&&(i==wr_ptr)&&wr_en[0]) || (v_ldq_ack_flag[1]&&(i==DEPTH_WIDTH'(wr_ptr+1))&&wr_en[0]))begin
                    v_entry_stq_flag[i] <= 1'b1;
                end
                else if ((rd_en) && (i==rd_ptr))begin
                    v_entry_stq_flag[i] <= 1'b0;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_mem_req[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_entry_mem_req[i] <= 1'b0;
                end
                else if((s_mem_req_vld&&s_mem_req_rdy) &&((mem_req_bypass && (i==wr_ptr))||(~mem_req_bypass && (i==mem_not_req_entry_id))) )begin
                    v_entry_mem_req[i] <= 1'b1;
                end
                else if ((rd_en) && (i==rd_ptr))begin
                    v_entry_mem_req[i] <= 1'b0;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_mem_ack[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_entry_mem_ack[i] <= 1'b0;
                end
                else if ((DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband[DEPTH_WIDTH-1:0])==i)&&(m_mem_ack_vld))begin
                    v_entry_mem_ack[i] <= 1'b1;
                end
                else if ((rd_en) && (i==rd_ptr))begin
                    v_entry_mem_ack[i] <= 1'b0;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_stq_ack_flag[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_stq_ack_flag[i] <= 1'b0;
                end
                else if (((wr_ptr==i)&&(v_ldq_ack_flag[0])) ||(DEPTH_WIDTH'(wr_ptr+1)==i)&&(v_ldq_ack_flag[1]) )begin
                    v_stq_ack_flag[i] <= 1'b1;
                end
                else if ((rd_en) && (i==rd_ptr))begin
                    v_stq_ack_flag[i] <= 1'b0;
                end
            end


            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_en[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_entry_en[i] <= 1'b0;
                end
                else if(((wr_en[0])&&(i==wr_ptr)) ||((wr_en[1])&&(i==(DEPTH_WIDTH'(wr_ptr+1)))) ) begin
                    v_entry_en[i] <= 1'b1;
                end
                else if ((rd_en) && (i==rd_ptr))begin
                    v_entry_en[i] <= 1'b0;
                end
            end

        end
    endgenerate



    // `ifdef TOY_SIM

    //     initial begin
    //         int file_handle;
    //         file_handle = $fopen("mem_wrback.log", "w");

    //         forever begin
    //             @(posedge clk)begin
    //             for (int i=0;i<2;i=i+1)begin
    //                 if(reg_wr_en[i]) begin
    //                     $fdisplay(file_handle, "[pc=%h][rd_val=%h]",s_load_pld[i].pc,reg_val[i]  );
    //                 end
    //             end
    //             if (reg_wr_en[2])begin
    //                 $fdisplay(file_handle, "[pc=%h][rd_val=%h]",v_entry_pld[DEPTH_WIDTH'(m_mem_ack_pld.mem_ack_sideband)].pc,reg_val[2]  );
    //             end
    //             end
    //         end
    //     end
    // `endif











endmodule

