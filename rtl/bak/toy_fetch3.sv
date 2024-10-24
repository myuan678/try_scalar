
module toy_fetch3
    import toy_pack::*;
(
    input  logic                            clk                     ,
    input  logic                            rst_n                   ,

    // memory access
    input  logic                            mem_ack_vld             ,
    output logic                            mem_ack_rdy             ,
    input  logic [DATA_WIDTH-1       :0]    mem_ack_data            ,
    input  logic [FETCH_SB_WIDTH-1   :0]    mem_ack_sideband        ,
    output logic [ADDR_WIDTH-1       :0]    mem_req_addr            ,
    output logic [FETCH_SB_WIDTH-1   :0]    mem_req_sideband        ,
    output logic                            mem_req_vld             ,
    input  logic                            mem_req_rdy             ,

    // pc update
    input logic                             trap_pc_release_en      ,
    input logic                             trap_pc_update_en       ,
    input logic [ADDR_WIDTH-1        :0]    trap_pc_val             ,

    input logic                             jb_pc_release_en        ,
    input logic                             jb_pc_update_en         ,
    input logic [ADDR_WIDTH-1        :0]    jb_pc_val               ,
    // cancel
    input logic                             cancel_en               ,
    input logic                             cancel_edge_en          ,
    input logic [ADDR_WIDTH-1       :0]     fetch_update_pc         ,
    // commit 
    input logic                             commit_credit_rel_en    ,
    input logic  [2                 :0]     commit_credit_rel_num   ,                 
    // fetch to exec
    output logic [INST_READ_CHANNEL-1:0]    v_instruction_vld       ,
    input  logic [INST_READ_CHANNEL-1:0]    v_instruction_rdy       ,
    output logic [INST_WIDTH-1       :0]    v_instruction_pld [INST_READ_CHANNEL-1:0]  ,
    output logic [ADDR_WIDTH-1       :0]    v_instruction_pc  [INST_READ_CHANNEL-1:0]  ,
    output be_pkg                           v_inst_be_pld     [INST_READ_CHANNEL-1:0]  ,
    output logic [INST_IDX_WIDTH-1   :0]    v_instruction_idx [INST_READ_CHANNEL-1:0]
);

    //##############################################
    // parameter
    //############################################## 
    localparam  int unsigned CREDIT_DEPTH           = 128                           ;
    localparam  int unsigned BRANCH_WIDTH           = 3                             ;
    localparam  int unsigned ENTRY_WIDTH            = $clog2(CREDIT_DEPTH)          ;
    localparam  int unsigned INST_NUM_WIDTH         = $clog2(2*FETCH_WRITE_CHANNEL)+1; 
    //##############################################
    // logic  
    //##############################################
    logic                               pc_release_en           ;
    logic                               pc_update_en            ;
    logic                               branch_ack_vld          ;
    logic                               fetch_nxt_vld           ;
    logic                               fetch_nxt_rdy           ;
    logic                               commit_credit_can_use   ;
    logic [$clog2(COMMIT_QUEUE_DEPTH):0]commit_credit_cnt       ;
    logic [$clog2(COMMIT_QUEUE_DEPTH):0]commit_credit_sub       ;
    logic [INST_READ_CHANNEL-1  :0]     fetch_queue_vld         ;
    logic [INST_READ_CHANNEL-1  :0]     fetch_queue_rdy         ;
    logic [DATA_WIDTH-1         :0]     branch_ack_data         ;
    logic [INST_READ_CHANNEL-1  :0]     v_instruction_en        ;
    logic [ADDR_WIDTH-1         :0]     fetch_nxt_pc            ;
    logic [INST_NUM_WIDTH-1     :0]     fetch_nxt_num           ;
    logic [BRANCH_WIDTH-1       :0]     req_branch_id           ;
    logic [BRANCH_WIDTH-1       :0]     req_branch_id_nxt       ;
    logic [ENTRY_WIDTH-1        :0]     req_entry_id            ;
    logic [BRANCH_WIDTH-1       :0]     mem_ack_branch_id       ;
    logic [ENTRY_WIDTH-1        :0]     mem_ack_entry_id        ;
    logic [ENTRY_WIDTH-1        :0]     branch_ack_entry_id     ;
    logic [INST_IDX_WIDTH-1     :0]     instruction_idx_reg     ;
    logic [INST_READ_CHANNEL-1  :0]     is_call                 ;
    logic [INST_READ_CHANNEL-1  :0]     is_ret                  ;
    logic [INST_READ_CHANNEL-1  :0]     is_cext                 ;
    //##############################################
    // commit package 
    //##############################################
    generate
        for(genvar i=0;i<INST_READ_CHANNEL;i=i+1)begin
            assign is_call[i] = (({v_instruction_pld[i][14:12],v_instruction_pld[i][6:0]} == 10'b000_1100111) && ((v_instruction_pld[i][11:7] == 5'b00001) || (v_instruction_pld[i][11:7] == 5'b00101))) //jalr
                || ((v_instruction_pld[i][6:0] == 7'b1101111) && ((v_instruction_pld[i][11:7] == 5'b00001) || (v_instruction_pld[i][11:7] == 5'b00101)))                         //jal 
                || (({v_instruction_pld[i][15:12],v_instruction_pld[i][6:0]} == 11'b1001_00000_10) && (v_instruction_pld[i][11:7] != 5'b0));                                     //c.jalr 

            assign is_ret[i]  = (({v_instruction_pld[i][14:12],v_instruction_pld[i][6:0]} == 10'b000_1100111) && (v_instruction_pld[i][11:7] != v_instruction_pld[i][19:15]) && ((v_instruction_pld[i][19:15] == 5'b00001) || (v_instruction_pld[i][19:15] == 5'b00101)) && (v_instruction_pld[i][31:20] == 12'b0)) //jalr
                || (({v_instruction_pld[i][15:12],v_instruction_pld[i][6:0]} == 11'b1000_00000_10) && ((v_instruction_pld[i][11:7] == 5'b00001) || (v_instruction_pld[i][11:7] == 5'b00101)) && (v_instruction_pld[i][11:7] != 5'b00000))                                        //jalr
                || (({v_instruction_pld[i][15:12],v_instruction_pld[i][6:0]} == 11'b1001_00000_10) && (v_instruction_pld[i][11:7] == 5'b00101));                                                                                                           //c.jalr 

            assign is_cext[i] = v_instruction_pld[i][1:0]==2'b11 ? 1'b0 : 1'b1;
            assign v_inst_be_pld[i].is_call = is_call[i];
            assign v_inst_be_pld[i].is_ret  = is_ret[i];
            assign v_inst_be_pld[i].is_cext = is_cext[i];
            assign v_inst_be_pld[i].pc      = v_instruction_pc[i];
            assign v_inst_be_pld[i].bypass  = {$bits(bypass_pkg){1'b1}}; //todo for tao
        end
    endgenerate
    //##############################################
    // logic 
    //##############################################
    assign v_instruction_en     = v_instruction_vld & v_instruction_rdy        ;
    assign mem_ack_rdy          = 1'b1                                          ;
    assign mem_req_sideband     = {req_entry_id,req_branch_id_nxt}              ;
    assign mem_ack_branch_id    = mem_ack_sideband[BRANCH_WIDTH-1:0]            ;
    assign mem_ack_entry_id     = mem_ack_sideband[BRANCH_WIDTH+:ENTRY_WIDTH]   ;

    // Fetch PC =========================================================================
    toy_fetch_pc u_toy_fetch_pc (
        .clk                    (clk                    ),
        .rst_n                  (rst_n                  ),
        .mem_req_addr           (mem_req_addr           ),
        .mem_req_vld            (mem_req_vld            ),
        .mem_req_rdy            (mem_req_rdy            ),
        .fetch_nxt_vld          (fetch_nxt_vld          ),
        .fetch_nxt_pc           (fetch_nxt_pc           ),
        .fetch_nxt_num          (fetch_nxt_num          ),
        .fetch_nxt_rdy          (fetch_nxt_rdy          ),
        .trap_pc_release_en     (trap_pc_release_en     ), 
        .trap_pc_update_en      (trap_pc_update_en      ), 
        .trap_pc_val            (trap_pc_val            ), 
        .cancel_edge_en         (cancel_edge_en         ),
        .fetch_update_pc        (fetch_update_pc        )
        // .jb_pc_release_en       (jb_pc_release_en       ), 
        // .jb_pc_update_en        (jb_pc_update_en        ), 
        // .jb_pc_val              (jb_pc_val              ),
        // .pc_update_en           (pc_update_en           ),
        // .pc_release_en          (pc_release_en          )
    );

    // Branch filter ===============================================================
    toy_fetch_branch_filter #(
        .BRANCH_WIDTH(BRANCH_WIDTH),
        .CREDIT_DEPTH(CREDIT_DEPTH)
    )u_toy_fetch_branch_filter(
        .clk                    (clk                    ),
        .rst_n                  (rst_n                  ),
        .mem_ack_vld            (mem_ack_vld            ),
        .mem_ack_data           (mem_ack_data           ),
        .mem_ack_branch_id      (mem_ack_branch_id      ),
        .mem_ack_entry_id       (mem_ack_entry_id       ),
        .cancel_edge_en         (cancel_edge_en         ),
        // .pc_update_en           (pc_update_en           ),
        // .pc_release_en          (pc_release_en          ),
        .req_branch_id_nxt      (req_branch_id_nxt      ),
        .branch_ack_vld         (branch_ack_vld         ),
        .branch_ack_data        (branch_ack_data        ),
        .branch_ack_entry_id    (branch_ack_entry_id    )
    );


    // Instruction Buffer ===============================================================

    // every depth line is 16 bits 
    toy_fetch_queue2 #(
        .DEPTH          (CREDIT_DEPTH               )
    )
    u_fifo (
        .clk             (clk                        ),
        .rst_n           (rst_n                      ),
        .clear           (cancel_edge_en             ),
        .cancel_en       (cancel_en                  ),
        // .pc_release_en   (pc_release_en              ),
        .mem_req_entry_id(req_entry_id               ),
        .mem_ack_vld     (branch_ack_vld             ),
        .mem_ack_pld     (branch_ack_data            ),
        .mem_ack_entry_id(branch_ack_entry_id        ),
        .fetch_nxt_vld   (fetch_nxt_vld              ),
        .fetch_nxt_rdy   (fetch_nxt_rdy              ),
        .fetch_nxt_pc    (fetch_nxt_pc               ),
        .fetch_nxt_num   (fetch_nxt_num              ),
        .v_ack_vld       (fetch_queue_vld            ),
        .v_ack_rdy       (fetch_queue_rdy            ),
        .v_ack_pld_pc    (v_instruction_pc           ),
        .v_ack_pld       (v_instruction_pld          ));


    // always_ff @(posedge clk or negedge rst_n) begin
    //     if(~rst_n)              v_instruction_idx <= 0;
    //     else if(v_instruction_en) v_instruction_idx <= v_instruction_idx + 1;
    // end

    assign v_instruction_vld =  fetch_queue_vld & {INST_READ_CHANNEL{commit_credit_can_use}};
    assign fetch_queue_rdy = v_instruction_rdy & {INST_READ_CHANNEL{commit_credit_can_use}};

    assign commit_credit_can_use = (commit_credit_cnt > 4);

    assign commit_credit_sub = v_instruction_en[0] + v_instruction_en[1] + v_instruction_en[2] + v_instruction_en[3];
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            commit_credit_cnt <= COMMIT_QUEUE_DEPTH;
        end
        else if(cancel_edge_en)begin
            commit_credit_cnt <= COMMIT_QUEUE_DEPTH;
            
        end
        else if(|v_instruction_en | commit_credit_rel_en)begin
            commit_credit_cnt <= commit_credit_cnt + ($clog2(COMMIT_QUEUE_DEPTH)'(commit_credit_rel_num)) - commit_credit_sub ;
        end
    end

    generate
        for(genvar i = 0;i < INST_READ_CHANNEL;i = i + 1)begin :READ_CHANNLE_GEN
            if(i==0)begin : READ_CHANNLE_0_GEN
                always_comb begin 
                    if(v_instruction_en[i])begin
                        v_instruction_idx[i] = instruction_idx_reg + 1;
                    end
                    else begin
                        v_instruction_idx[i] = instruction_idx_reg;
                    end
                end
            end
            else begin : READ_CHANNLE_NEQ0_GEN
                always_comb begin 
                    if(v_instruction_en[i])begin
                        v_instruction_idx[i] = v_instruction_idx[i-1] + 1;
                    end
                    else begin
                        v_instruction_idx[i] = v_instruction_idx[i-1];
                    end
                end
            end
        end
    endgenerate
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)begin
                instruction_idx_reg <= 0-1;
            end
            else if(cancel_edge_en)begin
                instruction_idx_reg <= 0-1;
                
            end
            else if(|v_instruction_en)begin
                instruction_idx_reg <= v_instruction_idx[INST_READ_CHANNEL-1] ;
            end
        end

endmodule
