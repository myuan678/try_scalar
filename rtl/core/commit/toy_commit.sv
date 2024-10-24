module toy_commit 
    import toy_pack::*;
    (
    input   logic                               clk                                         ,
    input   logic                               rst_n                                       ,

    input   logic [INST_ALU_NUM-1       :0]     v_alu_commit_en                             ,
    input   commit_pkg                          v_alu_commit_pld        [INST_ALU_NUM-1 :0] ,

    input   logic [1                    :0]     v_stq_commit_en                             ,
    input   commit_pkg                          v_stq_commit_pld        [1              :0] ,
    output  logic [3                    :0]     v_st_ack_commit_en                          ,
    output  logic [$clog2(STU_DEPTH)-1  :0]     v_st_ack_commit_entry   [3              :0] ,

    input   logic [2                    :0]     v_ldq_commit_en                             ,
    input   commit_pkg                          v_ldq_commit_pld        [2              :0] ,

    input   logic                               fp_commit_en                                ,
    input   commit_pkg                          fp_commit_pld                               ,

    input   logic                               mext_commit_en                              ,
    input   commit_pkg                          mext_commit_pld                             ,

    input   logic                               csr_commit_en                               ,
    input   commit_pkg                          csr_commit_pld                              ,

    input   logic  [INST_READ_CHANNEL-1 :0]     v_instruction_vld                           ,
    input   logic  [INST_READ_CHANNEL-1 :0]     v_instruction_rdy                           ,
    // input   logic  [ADDR_WIDTH-1        :0]     v_instruction_pc  [INST_READ_CHANNEL-1:0]   ,
    input   logic  [INST_IDX_WIDTH-1    :0]     v_instruction_idx [INST_READ_CHANNEL-1:0]   ,
    input   fe_bypass_pkg                       v_inst_fe_pld     [INST_READ_CHANNEL-1:0]   ,

    output  logic                               cancel_en                                   ,
    output  logic                               cancel_edge_en                              ,

    output  logic  [7                    :0]    FCSR_backup                                 ,
    output  logic  [COMMIT_REL_CHANNEL-1 :0]    v_rf_commit_en                              ,
    output  commit_pkg                          v_rf_commit_pld     [COMMIT_REL_CHANNEL-1:0],
    
    output  logic  [COMMIT_REL_CHANNEL-1 :0]    v_commit_error_en                           ,
    output  be_pkg                              v_bp_commit_pld     [COMMIT_REL_CHANNEL-1:0],

    output  logic  [63                   :0]    csr_INSTRET                                 ,


    output  logic                               commit_credit_rel_en                        ,
    output  logic  [2                    :0]    commit_credit_rel_num                    
    
);
    //=================================================
    // logic 
    //=================================================
    localparam integer unsigned DEPTH_WIDTH     = $clog2(COMMIT_QUEUE_DEPTH)                ;
    localparam integer unsigned CANCEL_CNT_NUM  = 1                                         ;

    logic                                   rd_ptr_over                                     ;
    logic   [3                      :0]     cancel_cnt                                      ;
    logic   [11                     :0]     v_s_commit_en                                   ;
    logic   [COMMIT_QUEUE_DEPTH-1   :0]     v_commit_queue_en                               ;
    logic   [COMMIT_QUEUE_DEPTH-1   :0]     v_commit_queue_update_en                        ;
    logic   [COMMIT_QUEUE_DEPTH-1   :0]     v_nxt_pc_en                                     ;
    logic   [COMMIT_REL_CHANNEL-1   :0]     v_correct_en                                    ;
    logic   [COMMIT_REL_CHANNEL-1   :0]     v_cancel_edge_en                                ;
    logic   [COMMIT_REL_CHANNEL-1   :0]     v_commit_en_series                              ;
    logic   [INST_READ_CHANNEL-1    :0]     v_s_pc_en                                       ;
    logic   [COMMIT_QUEUE_DEPTH-1   :0]     v_pc_queue_en                                   ;
    logic   [COMMIT_QUEUE_DEPTH-1   :0]     v_pc_queue_update_en;

    logic   [DEPTH_WIDTH-1          :0]     rd_ptr                                          ;
    logic   [DEPTH_WIDTH-1          :0]     rd_ptr_nxt                                      ;
    logic   [DEPTH_WIDTH-1          :0]     rd_ptr_add                                      ;
    logic   [ADDR_WIDTH-1           :0]     commit_pc_store                                 ;

    logic   [11                     :0]     vv_commit_en        [COMMIT_QUEUE_DEPTH-1   :0] ;
    logic   [ADDR_WIDTH-1           :0]     v_nxt_pc            [COMMIT_QUEUE_DEPTH-1   :0] ;
    // logic   [ADDR_WIDTH-1           :0]     v_s_pc_pld          [INST_READ_CHANNEL-1    :0] ;
    logic   [ADDR_WIDTH-1           :0]     v_pc_queue_mem      [COMMIT_QUEUE_DEPTH-1   :0] ;
    logic   [INST_READ_CHANNEL-1    :0]     vv_pc_en            [COMMIT_QUEUE_DEPTH-1:0];

    fe_bypass_pkg                           v_be_queue_update_pld[COMMIT_QUEUE_DEPTH-1:0];
    commit_pkg                              v_commit_queue_mem  [COMMIT_QUEUE_DEPTH-1   :0] ;                
    commit_pkg                              v_s_commit_pld      [11                     :0] ;
    commit_pkg                              v_commit_queue_pld  [COMMIT_QUEUE_DEPTH-1   :0] ;
    commit_pkg                              v_commit_queue_update_pld  [COMMIT_QUEUE_DEPTH-1   :0] ;
    fe_bypass_pkg                           v_be_pld            [COMMIT_QUEUE_DEPTH-1:0];
    
    logic [ADDR_WIDTH-1:0]            v_full_offset       [COMMIT_REL_CHANNEL-1:0];


    //=================================================
    // flatten 12 to 128 cross bar
    //=================================================

    assign v_s_commit_en        = {csr_commit_en,mext_commit_en,fp_commit_en,v_ldq_commit_en,v_stq_commit_en,v_alu_commit_en};
    assign v_s_commit_pld[0]    = v_alu_commit_pld[0]   ;
    assign v_s_commit_pld[1]    = v_alu_commit_pld[1]   ;
    assign v_s_commit_pld[2]    = v_alu_commit_pld[2]   ;
    assign v_s_commit_pld[3]    = v_alu_commit_pld[3]   ;
    assign v_s_commit_pld[4]    = v_stq_commit_pld[0]   ;
    assign v_s_commit_pld[5]    = v_stq_commit_pld[1]   ;
    assign v_s_commit_pld[6]    = v_ldq_commit_pld[0]   ;
    assign v_s_commit_pld[7]    = v_ldq_commit_pld[1]   ;
    assign v_s_commit_pld[8]    = v_ldq_commit_pld[2]   ;
    assign v_s_commit_pld[9]    = fp_commit_pld         ; 
    assign v_s_commit_pld[10]   = mext_commit_pld       ;
    assign v_s_commit_pld[11]   = csr_commit_pld        ;

    generate 
        for (genvar i = 0;i<COMMIT_QUEUE_DEPTH ;i=i+1 ) begin
            for (genvar j = 0;j<12 ;j=j+1 ) begin
                assign vv_commit_en[i][j] = (i == v_s_commit_pld[j].inst_id) & v_s_commit_en[j];
            end
            assign v_commit_queue_update_pld[i] = ({$bits(commit_pkg){vv_commit_en[i][0]}} & v_s_commit_pld[0]) |
                        ({$bits(commit_pkg){vv_commit_en[i][1]}} & v_s_commit_pld[1]) |
                        ({$bits(commit_pkg){vv_commit_en[i][2]}} & v_s_commit_pld[2]) |
                        ({$bits(commit_pkg){vv_commit_en[i][3]}} & v_s_commit_pld[3]) |
                        ({$bits(commit_pkg){vv_commit_en[i][4]}} & v_s_commit_pld[4]) |
                        ({$bits(commit_pkg){vv_commit_en[i][5]}} & v_s_commit_pld[5]) |
                        ({$bits(commit_pkg){vv_commit_en[i][6]}} & v_s_commit_pld[6]) |
                        ({$bits(commit_pkg){vv_commit_en[i][7]}} & v_s_commit_pld[7]) |
                        ({$bits(commit_pkg){vv_commit_en[i][8]}} & v_s_commit_pld[8]) |
                        ({$bits(commit_pkg){vv_commit_en[i][9]}} & v_s_commit_pld[9]) |
                        ({$bits(commit_pkg){vv_commit_en[i][10]}} & v_s_commit_pld[10]) |
                        ({$bits(commit_pkg){vv_commit_en[i][11]}} & v_s_commit_pld[11]) ;
            assign v_commit_queue_update_en[i] = |vv_commit_en[i];
        end
    endgenerate
    //=================================================
    // flatten 4 to 128 cross bar
    //=================================================

    assign v_s_pc_en        = v_instruction_vld & v_instruction_rdy;
    // assign v_s_pc_pld       = v_instruction_pc   ;


    generate 
        for (genvar i = 0;i<COMMIT_QUEUE_DEPTH ;i=i+1 ) begin
            for (genvar j = 0;j<INST_READ_CHANNEL ;j=j+1 ) begin
                assign vv_pc_en[i][j] = (i == v_instruction_idx[j]) & v_s_pc_en[j];
            end
            assign v_be_queue_update_pld[i] = 
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][0]}} & v_inst_fe_pld[0]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][1]}} & v_inst_fe_pld[1]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][2]}} & v_inst_fe_pld[2]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][3]}} & v_inst_fe_pld[3]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][4]}} & v_inst_fe_pld[4]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][5]}} & v_inst_fe_pld[5]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][6]}} & v_inst_fe_pld[6]) |
                        ({($bits(fe_bypass_pkg)){vv_pc_en[i][7]}} & v_inst_fe_pld[7]) ;
            assign v_pc_queue_update_en[i] = |vv_pc_en[i];
        end
    endgenerate
    //=================================================
    // commit mem  
    //=================================================
    generate
        for(genvar i=0;i<COMMIT_QUEUE_DEPTH;i=i+1)begin
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_commit_queue_mem[i] <= {$bits(commit_pkg){1'b0}};
                end
                else if(v_commit_queue_update_en[i]==1'b1)begin
                    v_commit_queue_mem[i] <= v_commit_queue_update_pld[i];
                end
            end
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_commit_queue_en[i] <= 1'b0;
                end
                else if(cancel_en) begin
                    v_commit_queue_en[i] <= 1'b0;
                end
                else if(v_commit_queue_update_en[i]==1'b1) begin
                    v_commit_queue_en[i] <= 1'b1;
                end
                else if( |v_rf_commit_en && ((i>=rd_ptr) && (i<rd_ptr_nxt)) ||  (rd_ptr_over && ((i>=rd_ptr) || (i+COMMIT_QUEUE_DEPTH)<{rd_ptr_over,rd_ptr_nxt})) )  begin
                    v_commit_queue_en[i] <= 1'b0;
                end 
            end

            // always_ff @(posedge clk or negedge rst_n) begin
            //     if(~rst_n)begin
            //         v_pc_queue_mem[i] <= {(ADDR_WIDTH){1'b0}};
            //     end
            //     else if(v_pc_queue_update_en[i]==1'b1)begin
            //         v_pc_queue_mem[i] <= v_pc_queue_update_pld[i];
            //     end
            // end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_be_pld[i] <= {$bits(fe_bypass_pkg){1'b0}};
                end
                else if(v_pc_queue_update_en[i]==1'b1)begin
                    v_be_pld[i] <= v_be_queue_update_pld[i];
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_pc_queue_en[i] <= 1'b0;
                end
                else if(cancel_en) begin
                    v_pc_queue_en[i] <= 1'b0;
                end
                else if(v_pc_queue_update_en[i]==1'b1) begin
                    v_pc_queue_en[i] <= 1'b1;
                end
                else if( |v_rf_commit_en && ((i>=rd_ptr) && (i<rd_ptr_nxt)) ||  (rd_ptr_over && ((i>=rd_ptr) || (i+COMMIT_QUEUE_DEPTH)<{rd_ptr_over,rd_ptr_nxt})) )  begin
                    v_pc_queue_en[i] <= 1'b0;
                end 
            end

        end

    endgenerate



    //=================================================
    // rd logic  
    //=================================================
    assign rd_ptr_over = rd_ptr_nxt<rd_ptr  ;
    assign rd_ptr_nxt  = rd_ptr + rd_ptr_add;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            rd_ptr <= 0;
        end
        else if(cancel_en)begin
            rd_ptr <= 0;
        end
        else if(|v_rf_commit_en)begin
            rd_ptr <= rd_ptr_nxt;
        end
    end


    //todo need update
    always_comb begin
        if(&v_rf_commit_en[3:0])begin
            rd_ptr_add = 4;
        end
        else if(&v_rf_commit_en[2:0])begin
            rd_ptr_add = 3;
        end
        else if(&v_rf_commit_en[1:0])begin
            rd_ptr_add = 2;
        end
        else if(v_rf_commit_en[0])begin
            rd_ptr_add = 1;
        end
        else begin
            rd_ptr_add = 0;
        end
    end

    //=================================================
    // correct logic  
    //=================================================

    // always_ff @(posedge clk or negedge rst_n) begin
    //     if(~rst_n)begin
    //         commit_pc_store <= 0;
    //     end
    //     else if(|v_rf_commit_en)begin
    //         commit_pc_store <= v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc;
    //     end
    // end


    //=================================================
    // output logic  
    //=================================================

    assign cancel_edge_en           = |v_cancel_edge_en;

    assign commit_credit_rel_en     = |v_rf_commit_en;
    assign commit_credit_rel_num    = rd_ptr_add;

    assign v_rf_commit_en[0]        = v_commit_en_series[0];
    assign v_commit_error_en[0]     = v_cancel_edge_en[0];
    assign v_commit_en_series[0]    = v_commit_queue_en[rd_ptr] & v_pc_queue_en[rd_ptr];

    generate
        for(genvar i=1;i<COMMIT_REL_CHANNEL;i=i+1)begin
            assign v_commit_en_series[i]    = v_commit_en_series[i-1] & v_commit_queue_en[DEPTH_WIDTH'(rd_ptr+i)] & v_pc_queue_en[DEPTH_WIDTH'(rd_ptr+i)];
            assign v_rf_commit_en[i]        = v_commit_en_series[i] & (&v_correct_en[i-1:0]);
            assign v_commit_error_en[i]     = v_cancel_edge_en[i] & ~|v_cancel_edge_en[i-1:0];
        end
        for(genvar j=0;j<COMMIT_REL_CHANNEL;j=j+1)begin
            assign v_rf_commit_pld[j]       = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)];
            assign v_correct_en[j]          = (v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].tgt_pc == v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc);
            assign v_cancel_edge_en[j]      = ~v_correct_en[j] & v_commit_en_series[j] ;
            assign v_st_ack_commit_en[j]    = v_rf_commit_en[j] & v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].stq_commit_entry_en;
            assign v_st_ack_commit_entry[j] = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].stq_commit_entry;
            
            assign v_full_offset[j]                  = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc - v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].pred_pc;
            assign v_bp_commit_pld[j].bypass.offset  = v_commit_error_en[j] ? (v_full_offset[j]>>2) : v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].offset;
            assign v_bp_commit_pld[j].bypass.pred_pc = v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].pred_pc;
            assign v_bp_commit_pld[j].bypass.taken   = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].is_cext 
                                                    ? (v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc - v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc)!=2
                                                    : (((v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc - v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc)!=4) || (v_full_offset[j]>>2)!=(4'd7-(v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].pred_pc[ALIGN_WIDTH-1:0]>>2)));
            assign v_bp_commit_pld[j].bypass.tgt_pc  = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc;
            assign v_bp_commit_pld[j].is_call        = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].is_call;
            assign v_bp_commit_pld[j].is_ret         = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].is_ret;
            assign v_bp_commit_pld[j].is_last        = v_commit_error_en[j] ? 1'b1 : v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].is_last && v_rf_commit_en[j];
            assign v_bp_commit_pld[j].bypass.is_cext = v_commit_error_en[j] ? v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].is_cext : v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].is_cext;
            assign v_bp_commit_pld[j].bypass.carry   = v_commit_error_en[j] ? v_full_offset[j][1] : v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].carry;
            assign v_bp_commit_pld[j].pc             = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc;
            assign v_bp_commit_pld[j].taken_err      = v_bp_commit_pld[j].bypass.taken ^ v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].taken;
            assign v_bp_commit_pld[j].taken_pend     = v_commit_error_en[j] ? (v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].is_cext 
                                                    ? (v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc - v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc)!=2
                                                    : (((v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_nxt_pc - v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+j)].inst_pc)==4) && (v_full_offset[j]>>2)!=(4'd7-(v_be_pld[DEPTH_WIDTH'(rd_ptr+j)].pred_pc[ALIGN_WIDTH-1:0]>>2)))) : 1'b0;
        end

    endgenerate


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            cancel_cnt <= CANCEL_CNT_NUM;
        end
        else if(cancel_edge_en)begin
            cancel_cnt <= 0;
        end
        else if(cancel_cnt<CANCEL_CNT_NUM)begin
            cancel_cnt <= cancel_cnt + 1;
        end
        
    end
    assign cancel_en = cancel_edge_en | (cancel_cnt<CANCEL_CNT_NUM);

//==========================================================================
// csr inst num
//==========================================================================


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                 csr_INSTRET <= 64'b0;
        else if(v_rf_commit_en[3]) csr_INSTRET <= csr_INSTRET + 4;
        else if(v_rf_commit_en[2]) csr_INSTRET <= csr_INSTRET + 3;
        else if(v_rf_commit_en[1]) csr_INSTRET <= csr_INSTRET + 2;
        else if(v_rf_commit_en[0]) csr_INSTRET <= csr_INSTRET + 1;
    end
//==========================================================================
// Fcsr backup
//==========================================================================
    logic [7:0] fcsr_mask [COMMIT_REL_CHANNEL-1:0];
    logic [7:0] fcsr_data [COMMIT_REL_CHANNEL-1:0];
    logic [7:0] fcsr_mask_backup;
    logic [7:0] fcsr_data_backup;
    generate
        for(genvar m=COMMIT_REL_CHANNEL-1;m>=0;m=m-1)begin
            if(m==COMMIT_REL_CHANNEL-1)begin
                assign fcsr_mask[COMMIT_REL_CHANNEL-1] = 8'hff;
                assign fcsr_data[m] = v_rf_commit_pld[m].FCSR_en & v_rf_commit_pld[m].FCSR_data & {8{v_rf_commit_en[m]}};
            end
            else begin
                assign fcsr_mask[m] = (fcsr_mask[m+1] & ~v_rf_commit_pld[m+1].FCSR_en ) | {8{~v_rf_commit_en[m+1]}};
                assign fcsr_data[m] = fcsr_data[m+1] |(fcsr_mask[m] & v_rf_commit_pld[m].FCSR_en & v_rf_commit_pld[m].FCSR_data & {8{v_rf_commit_en[m]}});
            end
        end
    endgenerate
    assign fcsr_mask_backup = fcsr_mask[0] & ~v_rf_commit_pld[0].FCSR_en | {8{~v_rf_commit_en[0]}};
    assign fcsr_data_backup = fcsr_data[0] | (fcsr_mask_backup & FCSR_backup);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            FCSR_backup <= 8'b0;
        end
        else if(~&fcsr_mask_backup & |v_rf_commit_en)begin
            FCSR_backup <= fcsr_data_backup;
        end
        
    end



//===============================================================================
// Simulation
//===============================================================================

    `ifdef TOY_SIM
    logic [63:0] cycle;
    logic [63:0] pred_num;
    logic [63:0] cancel_inst_cnt;
    logic [REG_WIDTH-1       :0] v_reg_phy_data [PHY_REG_NUM-1 :0];
    logic [PHY_REG_ID_WIDTH-1:0] v_reg_phy_id [ARCH_ENTRY_NUM-1:0];

    logic [3:0] ras_error;
    logic [3:0] offset_error;
    logic [3:0] taken_error;
    logic [3:0] ras_miss_error;
    logic [3:0] ind_error;
    logic [63:0] ras_error_cnt;
    logic [63:0] btb_error_cnt;
    logic [63:0] ind_btb_error_cnt;
    logic [63:0] ras_miss_error_cnt;
    logic [63:0] tage_error_cnt;
    

    generate
        for(genvar a=0;a<COMMIT_REL_CHANNEL;a=a+1)begin
            assign ras_error[a] = (v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+a)].is_ret && v_be_pld[DEPTH_WIDTH'(rd_ptr+a)].is_ret);
            assign offset_error[a] = (v_full_offset[a]>>2) != v_be_pld[DEPTH_WIDTH'(rd_ptr+a)].offset;
            assign taken_error[a] = (v_bp_commit_pld[a].bypass.taken != v_be_pld[DEPTH_WIDTH'(rd_ptr+a)].taken);
            assign ras_miss_error[a] = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+a)].is_ret;
            assign ind_error[a] = v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+a)].is_ind && ~v_commit_queue_mem[DEPTH_WIDTH'(rd_ptr+a)].is_ret;
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin                     
            ras_error_cnt <= 0;
            btb_error_cnt <= 0;
            tage_error_cnt <= 0;
            ras_miss_error_cnt <= 0;
            ind_btb_error_cnt <= 0;
        end
        else if(cancel_edge_en) begin         
            ras_error_cnt <=  (|(v_commit_error_en&(ras_error&~offset_error&~taken_error))) ? (ras_error_cnt + 1)  : ras_error_cnt;
            btb_error_cnt <=  (|(v_commit_error_en&(~taken_error))) ? (btb_error_cnt + 1)  : btb_error_cnt;
            tage_error_cnt <= (|(v_commit_error_en&taken_error)) ? (tage_error_cnt + 1) : tage_error_cnt;
            ras_miss_error_cnt <= (|(v_commit_error_en&(~taken_error)&ras_miss_error)) ? (ras_miss_error_cnt + 1)  : ras_miss_error_cnt;
            ind_btb_error_cnt <= (|(v_commit_error_en&(~taken_error)&ind_error)) ? (ind_btb_error_cnt + 1)  : ind_btb_error_cnt;
        end
    end 



    assign v_reg_phy_data = u_toy_scalar.u_core.u_dispatch.u_int_regfile.u_toy_physicial_regfile.v_reg_phy_data;
    assign v_reg_phy_id = u_toy_scalar.u_core.u_dispatch.u_int_regfile.u_toy_backup_rename_regfile.v_reg_phy_id;

    initial begin
        string  fname1   ;
        int     fhandle1 ;
        if($value$plusargs("REG_TRACE=%s", fname1)) begin
            fhandle1 = $fopen(fname1, "w");
            forever begin
                @(posedge clk)
                // for(int a=0;a<COMMIT_REL_CHANNEL;a=a+1)begin
                    if(|v_rf_commit_en) begin
                        // $fdisplay(fhandle, "[pc=%h][inst_id=%h][cycle=%0d]", v_rf_commit_pld[a].inst_pc, v_rf_commit_pld[a].inst_id, cycle);
                        $fdisplay(fhandle1, "[pc=%h][cycle=%0d][00:%h 01:%h 02:%h 03:%h 04:%h 05:%h 06:%h 07:%h 08:%h 09:%h 10:%h 11:%h 12:%h 13:%h 14:%h 15:%h 16:%h 17:%h 18:%h 19:%h 20:%h 21:%h 22:%h 23:%h 24:%h 25:%h 26:%h 27:%h 28:%h 29:%h 30:%h 31:%h]",
                        v_rf_commit_pld[0].inst_pc, cycle,
                        v_reg_phy_data[v_reg_phy_id[0]]  ,
                        v_reg_phy_data[v_reg_phy_id[1]]  ,
                        v_reg_phy_data[v_reg_phy_id[2]]  ,
                        v_reg_phy_data[v_reg_phy_id[3]]  ,
                        v_reg_phy_data[v_reg_phy_id[4]]  ,
                        v_reg_phy_data[v_reg_phy_id[5]]  ,
                        v_reg_phy_data[v_reg_phy_id[6]]  ,
                        v_reg_phy_data[v_reg_phy_id[7]]  ,
                    
                        v_reg_phy_data[v_reg_phy_id[8]]  ,
                        v_reg_phy_data[v_reg_phy_id[9]] ,
                        v_reg_phy_data[v_reg_phy_id[10]] ,
                        v_reg_phy_data[v_reg_phy_id[11]] ,
                        v_reg_phy_data[v_reg_phy_id[12]] ,
                        v_reg_phy_data[v_reg_phy_id[13]] ,
                        v_reg_phy_data[v_reg_phy_id[14]] ,
                        v_reg_phy_data[v_reg_phy_id[15]] ,
                    
                        v_reg_phy_data[v_reg_phy_id[16]] ,
                        v_reg_phy_data[v_reg_phy_id[17]] ,
                        v_reg_phy_data[v_reg_phy_id[18]] ,
                        v_reg_phy_data[v_reg_phy_id[19]] ,
                        v_reg_phy_data[v_reg_phy_id[20]] ,
                        v_reg_phy_data[v_reg_phy_id[21]] ,
                        v_reg_phy_data[v_reg_phy_id[22]] ,
                        v_reg_phy_data[v_reg_phy_id[23]] ,

                        v_reg_phy_data[v_reg_phy_id[24]] ,
                        v_reg_phy_data[v_reg_phy_id[25]] ,
                        v_reg_phy_data[v_reg_phy_id[26]] ,
                        v_reg_phy_data[v_reg_phy_id[27]] ,
                        v_reg_phy_data[v_reg_phy_id[28]] ,
                        v_reg_phy_data[v_reg_phy_id[29]] ,
                        v_reg_phy_data[v_reg_phy_id[30]] ,
                        v_reg_phy_data[v_reg_phy_id[31]] ,
                         
                         );
                    end
                end
            end
        // end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)  cycle <= 0;
        else        cycle <= cycle + 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                      cancel_inst_cnt <= 0;
        else if(cancel_edge_en)         cancel_inst_cnt <= cancel_inst_cnt + 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                 pred_num <= 64'b0;
        else if(v_rf_commit_en[3]) pred_num <= pred_num + 4;
        else if(v_rf_commit_en[2]) pred_num <= pred_num + 3;
        else if(v_rf_commit_en[1]) pred_num <= pred_num + 2;
        else if(v_rf_commit_en[0]) pred_num <= pred_num + 1;
    end

    logic [63:0] inst_1k;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                 inst_1k <= 64'b0;
        else if(inst_1k>=99999)    inst_1k <= 64'b0;
        else if(v_rf_commit_en[3]) inst_1k <= inst_1k + 4;
        else if(v_rf_commit_en[2]) inst_1k <= inst_1k + 3;
        else if(v_rf_commit_en[1]) inst_1k <= inst_1k + 2;
        else if(v_rf_commit_en[0]) inst_1k <= inst_1k + 1;
    end
    logic [63:0] num_error;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            num_error <= 0;
        end
        else if(inst_1k>=99999)begin
            num_error <= 0;
        end
        else if(cancel_edge_en)begin
            num_error <= num_error + 1;
        end
    end

    logic [63:0] btb_error_cnt_;
    logic [63:0] tage_error_cnt_;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin                     
            btb_error_cnt_ <= 0;
            tage_error_cnt_ <= 0;
        end
        else if(inst_1k>=99999)begin
            btb_error_cnt_ <= 0;
            tage_error_cnt_ <= 0;
        end
        else if(cancel_edge_en) begin         
            btb_error_cnt_ <=  (|(v_commit_error_en&(~taken_error))) ? (btb_error_cnt_ + 1)  : btb_error_cnt_;
            tage_error_cnt_ <= (|(v_commit_error_en&taken_error)) ? (tage_error_cnt_ + 1) : tage_error_cnt_;
        end
    end

    initial begin
        forever begin
            @(posedge clk)
            for(int a=0;a<COMMIT_REL_CHANNEL;a=a+1)begin
                if(v_commit_error_en[a]) begin
                    if (!taken_error[a] && !offset_error[a] && ras_error[a]) begin 
                        $display("[pc=%h][inst=%h][cycle=%0d]:ERROR TYPE: ras ERROR", v_bp_commit_pld[a].pc, v_be_pld[DEPTH_WIDTH'(rd_ptr+a)].inst_pld, cycle);
                    end
                    
                end
            end
        end
    end
    

    initial begin
        forever begin
            @(posedge clk)
            if(inst_1k>=99999) begin
                $display("[cycle=%0d][mpki=%0f][tage error=%0d][btb error=%0d]", cycle, (real'(num_error) * 1000.0) / real'(inst_1k), tage_error_cnt_, btb_error_cnt_);
            end
        end
    end

    logic [31:0] real_next_pc;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                 real_next_pc <= 32'h8000_0000;
        else if(v_rf_commit_en[3]) real_next_pc <= v_bp_commit_pld[3].bypass.tgt_pc;
        else if(v_rf_commit_en[2]) real_next_pc <= v_bp_commit_pld[2].bypass.tgt_pc;
        else if(v_rf_commit_en[1]) real_next_pc <= v_bp_commit_pld[1].bypass.tgt_pc;
        else if(v_rf_commit_en[0]) real_next_pc <= v_bp_commit_pld[0].bypass.tgt_pc;
    end

    initial begin
        forever begin
            @(posedge clk)
            for(int a=0; a<COMMIT_REL_CHANNEL;a=a+1)begin
                if(v_rf_commit_en[a]) begin
                    if((a==0) && (v_rf_commit_pld[a].inst_pc!=real_next_pc)) begin
                        $display("Error Detect: [pc=%h][pc_next=%h][cycle=%0d]", v_rf_commit_pld[a].inst_pc, real_next_pc, cycle);
                    end else if(v_rf_commit_pld[a].inst_pc!=v_rf_commit_pld[a-1].inst_nxt_pc) begin
                        $display("Error Detect: [pc=%h][pc_next=%h][cycle=%0d]", v_rf_commit_pld[a].inst_pc, real_next_pc, cycle);
                    end
                end
            end
        end
    end


    initial begin
        string  fname   ;
        int     fhandle ;
        if($value$plusargs("PC=%s", fname)) begin
            fhandle = $fopen(fname, "w");
            forever begin
                @(posedge clk)
                for(int a=0;a<COMMIT_REL_CHANNEL;a=a+1)begin
                    if(v_rf_commit_en[a]) begin
                        // $fdisplay(fhandle, "[pc=%h][inst_id=%h][cycle=%0d]", v_rf_commit_pld[a].inst_pc, v_rf_commit_pld[a].inst_id, cycle);
                        $fdisplay(fhandle, "[pc=%h][inst=%h][inst_id=%h][cycle=%0d][btb err: %0d]", v_rf_commit_pld[a].inst_pc, v_be_pld[DEPTH_WIDTH'(rd_ptr+a)].inst_pld, v_rf_commit_pld[a].inst_id, cycle, (v_commit_error_en[a]&(~taken_error[a])));
                    end
                end
            end
        end
    end

    initial begin
        if($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk)
                for(int a=0;a<COMMIT_REL_CHANNEL;a=a+1)begin
                    if(v_rf_commit_en[a]) begin
                        $display("[pc=%h][inst_id=%h][cycle=%0d]", v_rf_commit_pld[a].inst_pc,v_rf_commit_pld[a].inst_id, cycle);
                    end
                end
            end
        end
    end

    `endif


endmodule