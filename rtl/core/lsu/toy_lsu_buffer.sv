module toy_lsu_buffer 
    import toy_pack::*;
#(
    parameter   int unsigned S_CHANNEL  = 4                     ,
    parameter   int unsigned DEPTH      = 16                    
)
(
    input  logic                                clk                             ,
    input  logic                                rst_n                           ,

    input  logic [S_CHANNEL-1       :0]         v_s_lsu_vld                     ,
    input  lsu_pkg                              v_s_lsu_pld [S_CHANNEL-1    :0] ,
    output logic [S_CHANNEL-1       :0]         v_s_lsu_rdy                     ,

    output logic [STU_CHANNEL-1     :0]         v_m_stu_vld                     ,
    output logic [LDU_CHANNEL-1     :0]         v_m_ldu_vld                     ,
    input  logic [1                 :0]         v_lsu_rdy                       ,
    input  logic [1                 :0]         v_ldq_rdy                       ,
    input  logic                                stq_rdy                         ,
    output lsu_pkg                              v_m_stu_pld [LDU_CHANNEL-1  :0] ,
    output lsu_pkg                              v_m_ldu_pld [LDU_CHANNEL-1  :0] ,

    input logic                                 cancel_en                       ,

    input logic                                 stu_credit_en                   ,
    input logic  [3                 :0]         stu_credit_num                  ,
    input logic  [$clog2(STU_DEPTH)-1:0]        stq_commit_cnt                  ,

    input logic                                 ldu_credit_en                   ,
    input logic  [3                 :0]         ldu_credit_num                  
);

//==============================
    // parameter
    //==============================
    localparam DEPTH_WIDTH = $clog2(DEPTH)                          ;
    localparam QUEUE_CNT_WIDTH = $clog2(DEPTH)+1                    ;

    //============================== 
    // logic
    //==============================
    genvar i;
    logic                               stu_credit_can_use          ;
    logic                               ldu_credit_can_use          ;
    logic                               wr_en                       ;
    logic                               wr_ptr_over                 ;
    logic                               rd_ptr_over                 ;
    logic [3                    :0]     v_rd_en                     ;
    logic [$clog2(DEPTH)-1      :0]     rd_ptr                      ;
    logic [$clog2(DEPTH)-1      :0]     rd_ptr_nxt                  ;
    logic [$clog2(DEPTH)-1      :0]     wr_ptr                      ;
    logic [$clog2(DEPTH)-1      :0]     wr_ptr_nxt                  ;
    logic [DEPTH-1              :0]     v_pld_en                    ;
    logic [$clog2(STU_DEPTH)    :0]     stu_credit_cnt              ;
    logic [$clog2(LDU_DEPTH)    :0]     ldu_credit_cnt              ;
    logic [1                    :0]     stu_sub                     ;
    logic [1                    :0]     ldu_sub                     ;
    logic [3                    :0]     stu_add                     ;
    logic [3                    :0]     ldu_add                     ;
    logic [1                    :0]     v_pld_stu_en                ;
    logic [1                    :0]     v_pld_ldu_en                ;  
    logic [1                    :0]     rd_ptr_add                  ;         

    logic [QUEUE_CNT_WIDTH-1    :0]     queue_cnt                   ;
    logic [QUEUE_CNT_WIDTH-1    :0]     queue_calculate             ;
    logic [QUEUE_CNT_WIDTH-1    :0]     queue_residue               ;
    logic [1:0] v_m_lsu_vld;

    logic [$clog2(S_CHANNEL)    :0]     s_order     [S_CHANNEL-1    :0] ;
    logic [DEPTH-1              :0]     v_wr_bitmap [S_CHANNEL-1    :0] ;
    lsu_pkg                             v_pld_mem   [DEPTH-1        :0] ;
    lsu_pkg                             v_m_pld     [LDU_CHANNEL-1  :0] ;




    //==============================
    // logic 
    //==============================
    assign wr_en = |(v_s_lsu_vld & v_s_lsu_rdy);

    assign wr_ptr_nxt = wr_ptr + s_order[S_CHANNEL-1];
    assign wr_ptr_over = wr_ptr_nxt<wr_ptr  ;
    assign v_rd_en =   {v_m_stu_vld,v_m_ldu_vld} & {v_lsu_rdy,v_ldq_rdy};
    
    assign rd_ptr_add = 3'(v_rd_en[0] + v_rd_en[1] + v_rd_en[2] +v_rd_en[3]);

    //==============================
    // ready 
    //==============================
    assign queue_calculate = s_order[S_CHANNEL-1] - QUEUE_CNT_WIDTH'(rd_ptr_add);
    assign queue_residue = DEPTH - queue_cnt;
    always_ff @(posedge clk or negedge rst_n ) begin
        if(~rst_n)begin
            queue_cnt <= 0;
        end
        else if(cancel_en)begin
            queue_cnt <= 0;
        end
        else if(|v_rd_en | wr_en)begin
            queue_cnt <= queue_cnt + queue_calculate;
        end
    end

    assign v_s_lsu_rdy = (queue_residue>=4) ? 4'b1111:4'b0;

    //==============================
    // credit
    //==============================


    assign stu_sub = v_m_stu_vld[1] ? 2'd2 :
                     (v_m_stu_vld[0] & stq_rdy) ? 2'd1 : 2'd0;
    assign ldu_sub = (v_m_ldu_vld[1] & v_ldq_rdy[1]) ? 2'd2 :
                     (v_m_ldu_vld[0] & v_ldq_rdy[0]) ? 2'd1 : 2'd0;
    assign stu_add = stu_credit_en ? stu_credit_num : 0 ;
    assign ldu_add = ldu_credit_en ? ldu_credit_num : 0 ;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            stu_credit_cnt <= STU_DEPTH;
        end
        else if(cancel_en)begin
            stu_credit_cnt <= STU_DEPTH - stq_commit_cnt;
        end
        else if((|stu_sub) || stu_credit_en)begin
            stu_credit_cnt <= stu_credit_cnt + stu_add - stu_sub;
        end
    end
    assign stu_credit_can_use = (stu_credit_cnt>1);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            ldu_credit_cnt <= LDU_DEPTH;
        end
        else if(cancel_en)begin
            ldu_credit_cnt <= LDU_DEPTH;
        end
        else if((|ldu_sub) || ldu_credit_en)begin
            ldu_credit_cnt <= ldu_credit_cnt + ldu_add - ldu_sub;
        end
    end

    assign ldu_credit_can_use = (ldu_credit_cnt>1);

    //==============================
    // wr ptr
    //==============================
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            wr_ptr <= 0;
        end
        else if(cancel_en)begin
            wr_ptr <= 0;
        end
        else begin
            wr_ptr <= wr_ptr_nxt;
        end
    end

    //==============================
    // rd ptr
    //==============================
    assign rd_ptr_nxt = rd_ptr + rd_ptr_add;
    assign rd_ptr_over = rd_ptr_nxt<rd_ptr  ;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            rd_ptr <= 0;
        end
        else if(cancel_en)begin
            rd_ptr <= 0;
            
        end
        else begin
            rd_ptr <= rd_ptr_nxt;
        end
    end

    //==============================
    // read control 
    //==============================


    assign v_m_lsu_vld = {v_pld_en[DEPTH_WIDTH'(rd_ptr+1)],v_pld_en[rd_ptr]};

    assign v_pld_stu_en   = {v_m_pld[1].stu_en,v_m_pld[0].stu_en};
    assign v_m_stu_vld[0] = ((v_m_lsu_vld[0] && v_pld_ldu_en[0] && v_m_lsu_vld[1] && v_pld_stu_en[1]) || (v_m_lsu_vld[0] && v_pld_stu_en[0])) && stu_credit_can_use;
    assign v_m_stu_vld[1] = v_m_lsu_vld[0] && v_pld_stu_en[0] && v_m_lsu_vld[1] && v_pld_stu_en[1] && stu_credit_can_use;

    assign v_pld_ldu_en   = {v_m_pld[1].ldu_en,v_m_pld[0].ldu_en};
    assign v_m_ldu_vld[0] = ((v_m_lsu_vld[0] && v_pld_stu_en[0] && v_m_lsu_vld[1] && v_pld_ldu_en[1]) || (v_m_lsu_vld[0] && v_pld_ldu_en[0])) && ldu_credit_can_use;
    assign v_m_ldu_vld[1] = v_m_lsu_vld[0] && v_pld_ldu_en[0] && v_m_lsu_vld[1] && v_pld_ldu_en[1] && ldu_credit_can_use;

    assign v_m_stu_pld[1] = v_m_pld[1];
    assign v_m_ldu_pld[1] = v_m_pld[1];

    assign v_m_stu_pld[0] = (v_m_lsu_vld[0] && v_pld_stu_en[0]) ? v_m_pld[0] : v_m_pld[1];
    assign v_m_ldu_pld[0] = (v_m_lsu_vld[0] && v_pld_ldu_en[0]) ? v_m_pld[0] : v_m_pld[1];

    always_comb begin   
        v_m_pld[0]      = v_pld_mem[rd_ptr];
        v_m_pld[1]      = v_pld_mem[DEPTH_WIDTH'(rd_ptr+1)];
        v_m_pld[0].lsid = 1'b0;
        v_m_pld[1].lsid = 1'b1;
    end

    //==============================
    // mem control
    //==============================

    // wr control ----------------------------------------------------
    assign s_order[0] = (v_s_lsu_vld[0]&v_s_lsu_rdy[0]) ? 'd1 : 'd0;
    always_comb begin 
        v_wr_bitmap[0] = 0;
        v_wr_bitmap[0][wr_ptr] = v_s_lsu_vld[0]&v_s_lsu_rdy[0];
    end
    
    generate
        for(i=1;i<S_CHANNEL;i=i+1)begin
            always_comb begin
                if(v_s_lsu_vld[i]&v_s_lsu_rdy[i])begin
                    s_order[i] = s_order[i-1]+1;
                end
                else begin
                    s_order[i] = s_order[i-1];
                end
            end
            always_comb begin 
                v_wr_bitmap[i] = 0;
                v_wr_bitmap[i][DEPTH_WIDTH'(wr_ptr+s_order[i-1])] = v_s_lsu_vld[i]&v_s_lsu_rdy[i];
            end
        end
        
    // mem ----------------------------------------------------
        for (i=0;i<DEPTH;i=i+1)begin
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_pld_en[i] <= 1'b0;
                end
                else if(cancel_en)begin
                    v_pld_en[i] <= 1'b0;
                    
                end
                else if ( wr_en && ((i>=wr_ptr) && (i<wr_ptr_nxt)) ||  (wr_ptr_over && ((i>=wr_ptr) || (i+DEPTH)<{wr_ptr_over,wr_ptr_nxt})) )  begin
                    v_pld_en[i] <= 1'b1;
                end
                else if ( |v_rd_en && ((i>=rd_ptr) && (i<rd_ptr_nxt)) ||  (rd_ptr_over && ((i>=rd_ptr) || (i+DEPTH)<{rd_ptr_over,rd_ptr_nxt})) )  begin
                    v_pld_en[i] <= 1'b0;
                end
            end
            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    v_pld_mem[i] <= {$bits(lsu_pkg){1'b0}};
                end
                else begin
                    case ({v_wr_bitmap[0][i],v_wr_bitmap[1][i],v_wr_bitmap[2][i],v_wr_bitmap[3][i]})
                        4'b1000:v_pld_mem[i] <= v_s_lsu_pld[0];
                        4'b0100:v_pld_mem[i] <= v_s_lsu_pld[1];
                        4'b0010:v_pld_mem[i] <= v_s_lsu_pld[2];
                        4'b0001:v_pld_mem[i] <= v_s_lsu_pld[3];
                    endcase
                end
            end
        end
    endgenerate














endmodule