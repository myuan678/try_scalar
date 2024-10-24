module toy_stq 
    import toy_pack::*;
(
    input  logic                             clk                        ,
    input  logic                             rst_n                      ,

    input  logic  [1                    :0]  s_store_vld                ,
    input  stu_pkg                           s_store_pld        [1:0]   ,

    input  logic  [1                    :0]  s_load_vld                 ,
    input  ldu_pkg                           s_load_pld         [1:0]   ,
    output logic  [1                    :0]  v_lsu_half_word_rdy        ,
    output logic  [1                    :0]  v_ldq_rdy                  ,
    output logic                             stq_rdy                    ,

    output logic [1                     :0]  v_ldq_ack_en               ,
    output logic [1                     :0]  v_ldq_ack_flag             ,
    output ldq_ack_pkg                       v_ldq_ack_pld      [1:0]   ,

    output logic                             stq_credit_en              ,
    output logic [3                     :0]  stq_credit_num             ,     
    output logic [$clog2(STU_DEPTH)-1   :0]  stq_commit_cnt             ,

    output mem_req_pkg                       s_mem_req_pld              ,
    output logic                             s_mem_req_vld              ,
    input  logic                             s_mem_req_rdy              ,

    output logic [1                     :0]  v_stq_commit_en            ,
    output commit_pkg                        v_stq_commit_pld   [1:0]   ,

    input  logic                             cancel_en                  ,
    input  logic [3                     :0]  v_st_ack_commit_en         ,
    input  logic [$clog2(STU_DEPTH)-1   :0]  v_st_ack_commit_entry [3:0]   


);

    localparam integer unsigned DEPTH_WIDTH = $clog2(STU_DEPTH);

    stq_pkg                     v_entry_pld   [STU_DEPTH-1:0]  ;

    logic                       rd_en                   ;

    logic [3                :0] v_ld_en                 ;
    logic [STU_DEPTH-1      :0] mask_en                 ;
    logic [DEPTH_WIDTH-1    :0] wr_ptr                  ;
    logic [DEPTH_WIDTH-1    :0] rd_ptr                  ;
    logic [1                :0] wr_en                   ;
    logic [STU_DEPTH-1      :0] v_entry_en              ;
    logic [STU_DEPTH-1      :0] v_entry_commit          ;

    logic [DEPTH_WIDTH-1    :0] wr_ptr_commit           ;
    logic [DEPTH_WIDTH-1    :0] wr_ptr_commit_add       ;
    logic [DEPTH_WIDTH-1    :0] stq_commit_add          ;

    logic [STU_DEPTH-1      :0] v_hazard_check  [3:0]   ;
    logic [STU_DEPTH-1      :0] same_addr_en    [1:0]   ;
    logic [STU_DEPTH-1      :0] v_hazard_en     [1:0]   ;
    logic [DEPTH_WIDTH-1    :0] same_addr_index [1:0]   ;
    logic [DEPTH_WIDTH-1    :0] v_ld_bin        [3:0]   ;
    //========================
    // ld hazard
    //========================

    //hazard check first
    assign v_hazard_check[0] = v_hazard_en[0] & mask_en;
    assign v_hazard_check[1] = v_hazard_en[1] & mask_en;
    //hazard check second
    assign v_hazard_check[2] = v_hazard_en[0] & (~mask_en);
    assign v_hazard_check[3] = v_hazard_en[1] & (~mask_en);
    
    assign same_addr_en[0] = v_ld_en[0] | v_ld_en[2];
    assign same_addr_en[1] = v_ld_en[1] | v_ld_en[3];

    assign same_addr_index[0] = v_ld_en[0] ? v_ld_bin[0] : v_ld_bin[2];
    assign same_addr_index[1] = v_ld_en[1] ? v_ld_bin[1] : v_ld_bin[3];

    generate
        for(genvar j=0;j<4;j=j+1)begin
            cmn_lead_one_msb #(
                .ENTRY_NUM      (STU_DEPTH              )
                // .REQ_NUM        (1                      )
            ) u_hazard_ldone(
                .v_entry_vld    (v_hazard_check[j]      ),
                .v_free_idx_oh  (                       ),
                .v_free_idx_bin (v_ld_bin[j]            ),
                .v_free_vld     (v_ld_en[j]             )
            );
        end

        for(genvar i=0;i<STU_DEPTH;i=i+1)begin
            assign v_hazard_en[0][i] = v_entry_en[i] && (v_entry_pld[i].mem_req_addr == s_load_pld[0].mem_req_addr);
            assign v_hazard_en[1][i] = v_entry_en[i] && (v_entry_pld[i].mem_req_addr == s_load_pld[1].mem_req_addr);
            assign mask_en[i] = (i<=(DEPTH_WIDTH'(wr_ptr-1)));
        end
    endgenerate

    always_comb begin
        v_lsu_half_word_rdy = 2'b11;
        v_ldq_rdy           = 2'b11;
        stq_rdy             = 1'b1;
        if((s_load_vld[0] && s_store_vld[0]) && (s_store_pld[0].mem_req_addr == s_load_pld[0].mem_req_addr) && (s_load_pld[0].lsid))begin// check first
            if(s_store_pld[0].mem_req_strb != s_load_pld[0].mem_req_strb)begin
                v_lsu_half_word_rdy[1] = 1'b0;
                v_ldq_rdy[0] = 1'b0;
            end
        end
        else if(s_load_vld[0] && same_addr_en[0])begin
            if((v_entry_pld[same_addr_index[0]].mem_req_strb) != (s_load_pld[0].mem_req_strb))begin
                if(s_load_pld[0].lsid)begin
                    v_lsu_half_word_rdy[1] = 1'b0;
                    v_ldq_rdy[0] = 1'b0;
                end
                else begin
                    v_lsu_half_word_rdy = 2'b00;
                    stq_rdy = 1'b0;
                    v_ldq_rdy = 2'b00;
                end
            end
        end
        else if(s_load_vld[1] && same_addr_en[1])begin
            if(v_entry_pld[same_addr_index[1]].mem_req_strb != s_load_pld[1].mem_req_strb)begin
                v_lsu_half_word_rdy[1] = 1'b0;
                v_ldq_rdy[1] = 1'b0;
            end
        end
    end


    always_comb begin
        v_ldq_ack_flag[0] = 1'b0;
        v_ldq_ack_en[0]   = 1'b0;
        v_ldq_ack_pld[0] = {$bits(ldq_ack_pkg){1'b0}};

        if((s_load_vld[0] && s_store_vld[0]) && (s_store_pld[0].mem_req_addr == s_load_pld[0].mem_req_addr) && (s_load_pld[0].lsid))begin// check first
            if(s_store_pld[0].mem_req_strb == s_load_pld[0].mem_req_strb)begin
                v_ldq_ack_flag[0] = 1'b1;
                v_ldq_ack_pld[0].inst_id = s_load_pld[0].inst_id;
                v_ldq_ack_pld[0].inst_pc = s_load_pld[0].inst_pc;
                v_ldq_ack_pld[0].c_ext   = s_load_pld[0].c_ext;
                v_ldq_ack_pld[0].mem_req_data = s_store_pld[0].mem_req_data;
                v_ldq_ack_pld[0].arch_reg_index = s_load_pld[0].arch_reg_index;
                v_ldq_ack_pld[0].phy_reg_index = s_load_pld[0].inst_rd;
                v_ldq_ack_pld[0].rd_en = s_load_pld[0].inst_rd_en;
                v_ldq_ack_pld[0].fp_rd_en = s_load_pld[0].inst_fp_rd_en;
                v_ldq_ack_en[0]   = 1'b1;
            end
        end
        else if(s_load_vld[0] && same_addr_en[0])begin
            if(v_entry_pld[same_addr_index[0]].mem_req_strb == s_load_pld[0].mem_req_strb)begin
                v_ldq_ack_flag[0] = 1'b1;
                v_ldq_ack_pld[0].inst_id = s_load_pld[0].inst_id;
                v_ldq_ack_pld[0].c_ext   = s_load_pld[0].c_ext;
                v_ldq_ack_pld[0].inst_pc = s_load_pld[0].inst_pc;
                v_ldq_ack_pld[0].arch_reg_index = s_load_pld[0].arch_reg_index;
                v_ldq_ack_pld[0].phy_reg_index = s_load_pld[0].inst_rd;
                v_ldq_ack_pld[0].mem_req_data = v_entry_pld[same_addr_index[0]].mem_req_data;
                v_ldq_ack_pld[0].rd_en = s_load_pld[0].inst_rd_en;
                v_ldq_ack_pld[0].fp_rd_en = s_load_pld[0].inst_fp_rd_en;
                v_ldq_ack_en[0]   = 1'b1;
            end
        end
    end

    always_comb begin
        v_ldq_ack_flag[1] = 1'b0;
        v_ldq_ack_en[1]   = 1'b0;
        v_ldq_ack_pld[1] = {$bits(ldq_ack_pkg){1'b0}};
        if(s_load_vld[1] && same_addr_en[1])begin
            if(v_entry_pld[same_addr_index[1]].mem_req_strb == s_load_pld[1].mem_req_strb)begin
                v_ldq_ack_flag[1] = 1'b1;
                v_ldq_ack_en[1]   = 1'b1;
                v_ldq_ack_pld[1].inst_id = s_load_pld[1].inst_id;
                v_ldq_ack_pld[1].inst_pc = s_load_pld[1].inst_pc;
                v_ldq_ack_pld[1].c_ext   = s_load_pld[1].c_ext;
                v_ldq_ack_pld[1].arch_reg_index = s_load_pld[1].arch_reg_index;
                v_ldq_ack_pld[1].phy_reg_index = s_load_pld[1].inst_rd;
                v_ldq_ack_pld[1].rd_en = s_load_pld[1].inst_rd_en;
                v_ldq_ack_pld[1].fp_rd_en = s_load_pld[1].inst_fp_rd_en;
                v_ldq_ack_pld[1].mem_req_data = v_entry_pld[same_addr_index[1]].mem_req_data;
            end
        end
    end


    //======================
    // wr ptr
    //======================
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            wr_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(cancel_en)begin
            wr_ptr <= wr_ptr_commit;
        end
        else if(wr_en[1])begin
            wr_ptr <= wr_ptr + 2'd2;
        end
        else if(wr_en[0])begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    assign  wr_ptr_commit_add = v_st_ack_commit_en[0] + v_st_ack_commit_en[1] + v_st_ack_commit_en[2] + v_st_ack_commit_en[3];
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            wr_ptr_commit <= {DEPTH_WIDTH{1'b0}};
        end
        else if(|v_st_ack_commit_en)begin
            wr_ptr_commit <= wr_ptr_commit + wr_ptr_commit_add ;
        end
    end

    assign stq_commit_add = wr_ptr_commit_add - rd_en;
    always_ff @(posedge clk or negedge rst_n) begin 
        if(~rst_n)begin
            stq_commit_cnt <= {DEPTH_WIDTH{1'b0}};
        end
        else if(|v_st_ack_commit_en | rd_en)begin
            stq_commit_cnt <= stq_commit_cnt + stq_commit_add;
        end
        
    end

    //======================
    // rd ptr
    //======================
    assign rd_en = s_mem_req_vld && s_mem_req_rdy;
    always_ff @(posedge clk or negedge rst_n) begin 
        if(~rst_n)begin
            rd_ptr <= {DEPTH_WIDTH{1'b0}};
        end
        else if(rd_en)begin
            rd_ptr <= rd_ptr + 1'b1 ;
        end
    end

    assign s_mem_req_vld = v_entry_commit[rd_ptr];
    assign s_mem_req_pld.mem_req_addr = v_entry_pld[rd_ptr].mem_req_addr;
    assign s_mem_req_pld.mem_req_data = v_entry_pld[rd_ptr].mem_req_data;
    assign s_mem_req_pld.mem_req_strb = v_entry_pld[rd_ptr].mem_req_strb;
    assign s_mem_req_pld.mem_req_opcode = TOY_BUS_WRITE;
    assign s_mem_req_pld.mem_req_sideband = rd_ptr;

    //======================
    //stq_credit
    //======================

    assign stq_credit_en = rd_en;
    assign stq_credit_num = 4'd1;

    //======================
    // commit
    //======================

    assign v_stq_commit_en = wr_en;


    always_comb begin
        v_stq_commit_pld[0] = {$bits(commit_pkg){1'b0}};
        v_stq_commit_pld[1] = {$bits(commit_pkg){1'b0}};
        v_stq_commit_pld[0].inst_id = s_store_pld[0].inst_id;
        v_stq_commit_pld[0].inst_pc = s_store_pld[0].inst_pc;
        v_stq_commit_pld[0].inst_nxt_pc = s_store_pld[0].c_ext ? s_store_pld[0].inst_pc + 2 : s_store_pld[0].inst_pc + 4;
        v_stq_commit_pld[0].rd_en = 1'b0;
        v_stq_commit_pld[0].fp_rd_en = 1'b0;
        v_stq_commit_pld[0].stq_commit_entry_en = 1'b1;
        v_stq_commit_pld[0].stq_commit_entry = wr_ptr;
        v_stq_commit_pld[0].inst_val = 0;
        v_stq_commit_pld[0].is_cext  = s_store_pld[0].c_ext;
        v_stq_commit_pld[0].is_call  = 0;
        v_stq_commit_pld[0].is_ret   = 0;
        v_stq_commit_pld[0].FCSR_en  = 8'b0;
        v_stq_commit_pld[1].inst_id = s_store_pld[1].inst_id;
        v_stq_commit_pld[1].inst_pc = s_store_pld[1].inst_pc;
        v_stq_commit_pld[1].inst_nxt_pc = s_store_pld[1].c_ext ? s_store_pld[1].inst_pc + 2 :s_store_pld[1].inst_pc + 4;
        v_stq_commit_pld[1].rd_en = 1'b0;
        v_stq_commit_pld[1].fp_rd_en = 1'b0;
        v_stq_commit_pld[1].stq_commit_entry_en = 1'b1;
        v_stq_commit_pld[1].stq_commit_entry = DEPTH_WIDTH'(wr_ptr+1);
        v_stq_commit_pld[1].inst_val = 0;
        v_stq_commit_pld[1].is_cext  = s_store_pld[1].c_ext;
        v_stq_commit_pld[1].is_call  = 0;
        v_stq_commit_pld[1].is_ret   = 0;
        v_stq_commit_pld[1].FCSR_en  = 8'b0;
    end

    // assign v_stq_commit_pld[0].inst_id = s_store_pld[0].inst_id;
    // assign v_stq_commit_pld[0].inst_pc = s_store_pld[0].inst_pc;
    // assign v_stq_commit_pld[0].inst_nxt_pc = s_store_pld[0].c_ext ? s_store_pld[0].inst_pc + 2 : s_store_pld[0].inst_pc + 4;
    // assign v_stq_commit_pld[0].rd_en = 1'b0;
    // assign v_stq_commit_pld[0].fp_rd_en = 1'b0;
    // assign v_stq_commit_pld[0].stq_commit_entry_en = 1'b1;
    // assign v_stq_commit_pld[0].stq_commit_entry = wr_ptr;
    // assign v_stq_commit_pld[0].inst_val = 0;
    // assign v_stq_commit_pld[0].is_cext  = s_store_pld[0].c_ext;
    // assign v_stq_commit_pld[0].is_call  = 0;
    // assign v_stq_commit_pld[0].is_ret   = 0;
    // assign v_stq_commit_pld[0].FCSR_en  = 8'b0;

    // assign v_stq_commit_pld[1].inst_id = s_store_pld[1].inst_id;
    // assign v_stq_commit_pld[1].inst_pc = s_store_pld[1].inst_pc;
    // assign v_stq_commit_pld[1].inst_nxt_pc = s_store_pld[1].c_ext ? s_store_pld[1].inst_pc + 2 :s_store_pld[1].inst_pc + 4;
    // assign v_stq_commit_pld[1].rd_en = 1'b0;
    // assign v_stq_commit_pld[1].fp_rd_en = 1'b0;
    // assign v_stq_commit_pld[1].stq_commit_entry_en = 1'b1;
    // assign v_stq_commit_pld[1].stq_commit_entry = DEPTH_WIDTH'(wr_ptr+1);
    // assign v_stq_commit_pld[1].inst_val = 0;
    // assign v_stq_commit_pld[1].is_cext  = s_store_pld[1].c_ext;
    // assign v_stq_commit_pld[1].is_call  = 0;
    // assign v_stq_commit_pld[1].is_ret   = 0;
    // assign v_stq_commit_pld[1].FCSR_en  = 8'b0;
    //======================
    // commit ack
    //======================
    logic [STU_DEPTH-1:0] vv_commit_en [COMMIT_REL_CHANNEL-1:0];
    logic [STU_DEPTH-1:0] v_commit_en ;
    generate
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                vv_commit_en[i] = {STU_DEPTH{1'b0}};
                vv_commit_en[i][v_st_ack_commit_entry[i]] = v_st_ack_commit_en[i];

            end
        end
    endgenerate

    assign v_commit_en = vv_commit_en[0] | vv_commit_en[1] | vv_commit_en[2] | vv_commit_en[3];


    //======================
    // mem
    //======================

    assign wr_en[0] = s_store_vld[0] && stq_rdy;
    assign wr_en[1] = s_store_vld[1];
    generate
        for(genvar i=0;i<STU_DEPTH;i=i+1)begin
            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    v_entry_pld[i] <= {$bits(v_entry_pld){1'b0}};
                end
                else if((wr_en[0])&&(i==wr_ptr))begin
                    v_entry_pld[i].inst_id      <= s_store_pld[0].inst_id;
                    v_entry_pld[i].inst_pc      <= s_store_pld[0].inst_pc;
                    v_entry_pld[i].mem_req_addr <= s_store_pld[0].mem_req_addr;
                    v_entry_pld[i].mem_req_strb <= s_store_pld[0].mem_req_strb;
                    v_entry_pld[i].mem_req_data <= s_store_pld[0].mem_req_data;
                    v_entry_pld[i].c_ext        <= s_store_pld[0].c_ext;
                end
                else if((wr_en[1])&&(i==(DEPTH_WIDTH'(wr_ptr+1))))begin
                    v_entry_pld[i].inst_id      <= s_store_pld[1].inst_id;
                    v_entry_pld[i].inst_pc      <= s_store_pld[1].inst_pc;
                    v_entry_pld[i].mem_req_addr <= s_store_pld[1].mem_req_addr;
                    v_entry_pld[i].mem_req_strb <= s_store_pld[1].mem_req_strb;
                    v_entry_pld[i].mem_req_data <= s_store_pld[1].mem_req_data;
                    v_entry_pld[i].c_ext        <= s_store_pld[1].c_ext;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_en[i] <= 1'b0;
                end
                else if( (cancel_en & ~v_entry_commit[i]))begin
                    v_entry_en[i] <= 1'b0;
                end
                else if(((wr_en[0])&&(i==wr_ptr)) ||((wr_en[1])&&(i==(DEPTH_WIDTH'(wr_ptr+1)))) ) begin
                    v_entry_en[i] <= 1'b1;
                end
                else if(rd_en && (i==rd_ptr))begin
                    v_entry_en[i] <= 1'b0;
                end
            end


            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_entry_commit[i] <= 1'b0;
                end
                else if(v_commit_en[i]==1'b1) begin
                    v_entry_commit[i] <= 1'b1;
                end
                else if(rd_en && (i==rd_ptr))begin
                    v_entry_commit[i] <= 1'b0;
                end
            end


        end
    endgenerate












endmodule

