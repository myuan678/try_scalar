module toy_lsu 
    import toy_pack::*;
(
    input  logic                            clk                 ,
    input  logic                            rst_n               ,

    input  logic    [3:0]                   v_instruction_vld   ,
    output logic    [3:0]                   v_instruction_rdy   ,
    input  lsu_pkg                          v_lsu_pld [3:0]     ,
    // input  logic [INST_WIDTH-1:0]     instruction_pld     ,
    // input  logic [INST_IDX_WIDTH-1:0] instruction_idx     ,
    // input  logic [PHY_REG_ID_WIDTH-1:0]inst_rd_idx         ,
    // input  logic                      inst_rd_en          ,
    // input  logic                      inst_fp_rd_en       ,
    // input  logic [ADDR_WIDTH-1:0]     pc                  ,
    // input  logic [REG_WIDTH-1:0]      rs1_val             ,
    // input  logic [REG_WIDTH-1:0]      rs2_val             ,
    // input  logic [31:0]               inst_imm            ,

    // reg access
    output logic [PHY_REG_ID_WIDTH-1:0] reg_index  [2:0]         ,
    output logic [2                 :0] reg_wr_en                ,
    output logic [REG_WIDTH-1       :0] reg_val    [2:0]         ,
    
    output logic [2                 :0] fp_reg_wr_en             ,

    // output logic [INST_IDX_WIDTH-1:0] reg_inst_idx_wr     ,
    // output logic [INST_IDX_WIDTH-1:0] reg_inst_idx_rd     ,
    // output logic                      inst_commit_en_rd   ,
    // output logic                      inst_commit_en_wr   ,

    // commit 
    output logic [1                     :0]  v_stq_commit_en            ,
    output commit_pkg                        v_stq_commit_pld   [1:0]   ,

    input  logic [3                     :0]  v_st_ack_commit_en         ,
    input  logic [3                     :0]  v_st_ack_commit_cancel_en  ,
    input  logic [$clog2(STU_DEPTH)-1   :0]  v_st_ack_commit_entry [3:0],

    output logic [2                     :0]  v_ldq_commit_en            ,
    output commit_pkg                        v_ldq_commit_pld   [2:0]   ,

    input  logic                             cancel_en,
    input  logic                             cancel_edge_en,
    //mem access
    output logic                      mem_req_vld         ,
    input  logic                      mem_req_rdy         ,
    output logic [ADDR_WIDTH-1:0]     mem_req_addr        ,
    output logic [DATA_WIDTH-1:0]     mem_req_data        ,
    output logic [DATA_WIDTH/8-1:0]   mem_req_strb        ,
    output logic                      mem_req_opcode      ,
    output logic [FETCH_SB_WIDTH-1:0] mem_req_sideband    ,

    input  logic [FETCH_SB_WIDTH-1:0] mem_ack_sideband    ,
    input  logic                      mem_ack_vld         ,
    output logic                      mem_ack_rdy         ,
    input  logic [DATA_WIDTH-1:0]     mem_ack_data        

);


    logic           stq_rdy             ;
    logic           stq_credit_en       ;
    logic           ldq_credit_en       ;
    logic           stq_mem_req_vld     ;
    logic           stq_mem_req_rdy     ;
    logic           ldq_mem_req_vld     ;
    logic           ldq_mem_req_rdy     ;

    logic [1    :0] v_lsu_rdy           ;
    logic [1    :0] v_ldq_rdy           ;
    logic [1    :0] v_m_stu_vld         ;
    logic [1    :0] v_m_ldu_vld         ;
    logic [3    :0] stq_credit_num      ;
    logic [3    :0] ldq_credit_num      ;
    logic [1    :0] v_load_vld          ;
    logic [1    :0] v_store_vld         ;
    logic [1    :0] v_ldq_ack_en        ;
    logic [1    :0] v_ldq_ack_flag      ;
    logic [2    :0] req_branch_id_nxt   ;
    logic [2    :0] mem_ack_branch_id   ;

    logic [$clog2(STU_DEPTH)-1   :0]  stq_commit_cnt;

    mem_req_pkg     stq_mem_req_pld     ;    
    mem_req_pkg     ldq_mem_req_pld     ;
    mem_req_pkg     mem_req_pld         ;
    mem_ack_pkg     mem_ack_pld         ;
    lsu_pkg         v_m_stu_pld [1:0]   ;
    lsu_pkg         v_m_ldu_pld [1:0]   ;
    ldu_pkg         v_load_pld  [1:0]   ;
    stu_pkg         v_store_pld [1:0]   ;
    ldq_ack_pkg     v_ldq_ack_pld [1:0] ;

    toy_lsu_buffer #(
        .S_CHANNEL(4),
        .DEPTH(LSU_DEPTH)
    )u_toy_lsu_buffer(
        .clk            (clk                    ),
        .rst_n          (rst_n                  ),
        .v_s_lsu_vld    (v_instruction_vld      ),
        .v_s_lsu_pld    (v_lsu_pld              ),
        .v_s_lsu_rdy    (v_instruction_rdy      ),
        .v_m_stu_vld    (v_m_stu_vld            ),
        .v_m_ldu_vld    (v_m_ldu_vld            ),
        .v_lsu_rdy      (v_lsu_rdy              ),
        .v_ldq_rdy      (v_ldq_rdy              ),
        .stq_rdy        (stq_rdy                ),
        .v_m_stu_pld    (v_m_stu_pld            ),
        .v_m_ldu_pld    (v_m_ldu_pld            ),
        .cancel_en      (cancel_en              ),
        .stq_commit_cnt (stq_commit_cnt         ),
        .stu_credit_en  (stq_credit_en          ),
        .stu_credit_num (stq_credit_num         ),
        .ldu_credit_en  (ldq_credit_en          ),
        .ldu_credit_num (ldq_credit_num         )
    );

    generate
        for(genvar i=0;i<2;i++)begin
            toy_stu u_toy_stu(
                .clk        (clk                ),
                .rst_n      (rst_n              ),
                .s_store_vld(v_m_stu_vld[i]     ),
                .s_store_pld(v_m_stu_pld[i]     ),
                .m_store_pld(v_store_pld[i]     ),
                .m_store_vld(v_store_vld[i]     )
            );

            toy_ldu u_toy_ldu(
                .clk        (clk                ),
                .rst_n      (rst_n              ),
                .s_load_vld (v_m_ldu_vld[i]     ),
                .s_load_pld (v_m_ldu_pld[i]     ),
                .m_load_pld (v_load_pld[i]      ),
                .m_load_vld (v_load_vld[i]      )
            );

        end
    endgenerate

    toy_stq u_toy_stq(
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .s_store_vld        (v_store_vld        ),
        .s_store_pld        (v_store_pld        ),
        .s_load_vld         (v_load_vld         ),
        .s_load_pld         (v_load_pld         ),
        .v_lsu_half_word_rdy(v_lsu_rdy          ),
        .v_ldq_rdy          (v_ldq_rdy          ),
        .stq_rdy            (stq_rdy            ),
        .v_ldq_ack_en       (v_ldq_ack_en       ),
        .v_ldq_ack_flag     (v_ldq_ack_flag     ),
        .v_ldq_ack_pld      (v_ldq_ack_pld      ),
        .stq_credit_en      (stq_credit_en      ),
        .stq_credit_num     (stq_credit_num     ),
        .stq_commit_cnt     (stq_commit_cnt     ),
        .s_mem_req_pld      (stq_mem_req_pld    ),
        .s_mem_req_vld      (stq_mem_req_vld    ),
        .s_mem_req_rdy      (stq_mem_req_rdy    ),
        .v_stq_commit_en    (v_stq_commit_en    ),
        .v_stq_commit_pld   (v_stq_commit_pld   ),
        .cancel_en          (cancel_en          ),
        .v_st_ack_commit_en (v_st_ack_commit_en ),
        .v_st_ack_commit_entry(v_st_ack_commit_entry)
    );

    toy_ldq u_toy_ldq(
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .s_load_vld         (v_load_vld         ),
        .s_load_pld         (v_load_pld         ),
        .v_ldq_rdy          (v_ldq_rdy          ),
        .v_ldq_ack_en       (v_ldq_ack_en       ),
        .v_ldq_ack_flag     (v_ldq_ack_flag     ),
        .v_ldq_ack_pld      (v_ldq_ack_pld      ),
        .ldq_credit_en      (ldq_credit_en      ),
        .ldq_credit_num     (ldq_credit_num     ),
        .s_mem_req_pld      (ldq_mem_req_pld    ),
        .s_mem_req_vld      (ldq_mem_req_vld    ),
        .s_mem_req_rdy      (ldq_mem_req_rdy    ),
        .m_mem_ack_pld      (mem_ack_pld        ),
        .m_mem_ack_vld      (branch_ack_vld     ),
        .m_mem_ack_rdy      (mem_ack_rdy        ),
        .branch_id          (req_branch_id_nxt  ),
        .v_reg_index        (reg_index          ),
        .reg_wr_en          (reg_wr_en          ),
        .fp_reg_wr_en       (fp_reg_wr_en       ),
        .reg_val            (reg_val            ),
        .cancel_en          (cancel_en          ),
        .v_ldq_commit_en    (v_ldq_commit_en    ),
        .v_ldq_commit_pld   (v_ldq_commit_pld   )
    );

    cmn_fix_arb#(
        .PLD_TYPE           (mem_req_pkg        )
    ) u_cmn_fix_arb(
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .s_vld_priority     (ldq_mem_req_vld    ),
        .s_rdy_priority     (ldq_mem_req_rdy    ),
        .s_pld_priority     (ldq_mem_req_pld    ),
        .s_vld              (stq_mem_req_vld    ),
        .s_rdy              (stq_mem_req_rdy    ),
        .s_pld              (stq_mem_req_pld    ),
        .m_vld              (mem_req_vld        ),
        .m_rdy              (mem_req_rdy        ),
        .m_pld              (mem_req_pld        )
    );

    assign mem_ack_branch_id = mem_ack_pld.mem_ack_sideband[9:7];

    toy_ldq_branch_filter u_toy_ldq_branch_filter(

        .clk                     (clk                     ),
        .rst_n                   (rst_n                   ),
        .mem_ack_vld             (mem_ack_vld             ),
        .mem_ack_branch_id       (mem_ack_branch_id       ),
        .cancel_edge_en          (cancel_edge_en          ),
        .req_branch_id_nxt       (req_branch_id_nxt       ),
        .branch_ack_vld          (branch_ack_vld          )

    );

    assign mem_req_addr = mem_req_pld.mem_req_addr;
    assign mem_req_data = DATA_WIDTH'(mem_req_pld.mem_req_data) << (mem_req_pld.mem_req_addr[4:0]*8);
    assign mem_req_strb = 32'(mem_req_pld.mem_req_strb) << (mem_req_pld.mem_req_addr[4:0]);
    assign mem_req_sideband = mem_req_pld.mem_req_sideband;
    assign mem_req_opcode = mem_req_pld.mem_req_opcode;

    assign mem_ack_pld.mem_ack_data = mem_ack_data;
    assign mem_ack_pld.mem_ack_sideband = mem_ack_sideband;


    `ifdef TOY_SIM

        logic [31:0] fix_cycle;
        logic [31:0] mem_cycle;
        logic fix_priority;
        assign fix_priority = mem_req_vld && mem_req_rdy && ldq_mem_req_vld && stq_mem_req_vld;
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)begin
                mem_cycle <= 0;
            end
            else if(mem_req_vld && mem_req_rdy) begin
                mem_cycle <= mem_cycle + 1;
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)begin
                fix_cycle <= 0;
            end
            else if(fix_priority) begin
                fix_cycle <= fix_cycle + 1;
            end
        end

    `endif


endmodule