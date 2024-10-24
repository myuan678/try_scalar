
module toy_fetch_queue2 
    import toy_pack::*;
#(
    parameter   int unsigned DEPTH    = 128                     ,
    localparam  int unsigned FETCH_DATA_WIDTH = ADDR_WIDTH*FETCH_WRITE_CHANNEL,
    localparam  int unsigned INST_NUM_WIDTH   = $clog2(2*FETCH_WRITE_CHANNEL)+1
)(
    input   logic                               clk                 ,
    input   logic                               rst_n               ,

    input   logic                               clear               ,
    input   logic                               cancel_en           ,
    // input   logic                               pc_release_en       ,

    output  logic   [$clog2(DEPTH)-1        :0] mem_req_entry_id    ,

    input   logic                               mem_ack_vld         ,
    input   logic   [FETCH_DATA_WIDTH-1     :0] mem_ack_pld         ,
    input   logic   [$clog2(DEPTH)-1        :0] mem_ack_entry_id    ,

    output  logic                               fetch_nxt_vld       ,
    input   logic                               fetch_nxt_rdy       ,
    input   logic   [ADDR_WIDTH-1           :0] fetch_nxt_pc        ,
    input   logic   [INST_NUM_WIDTH-1       :0] fetch_nxt_num       ,
    
    output  logic   [INST_READ_CHANNEL-1    :0] v_ack_vld           ,
    input   logic   [INST_READ_CHANNEL-1    :0] v_ack_rdy           ,
    output  logic   [ADDR_WIDTH-1           :0] v_ack_pld_pc  [INST_READ_CHANNEL-1:0],
    output  logic   [INST_WIDTH-1           :0] v_ack_pld     [INST_READ_CHANNEL-1:0]
);


    //##############################################
    // parameter
    //##############################################
    localparam  int unsigned FETCH_WR_WIDTH         = $clog2(FETCH_WRITE_CHANNEL)       ;  
    localparam  int unsigned WR_PTR_ADD_FILL        = 2*FETCH_WRITE_CHANNEL             ;    
    localparam  int unsigned WR_PTR_CAL_WIDTH       = $clog2(WR_PTR_ADD_FILL) + 1       ; 
    localparam  int unsigned RD_PTR_CAL_WIDTH       = $clog2(2*INST_READ_CHANNEL) + 1   ;   
    localparam  int unsigned DEPTH_VECTOR           = 16*DEPTH                          ;    
    localparam  int unsigned DEPTH_VECTOR_WIDTH     = $clog2(16*DEPTH)                  ;   
    localparam  int unsigned DEPTH_WIDTH            = $clog2(DEPTH)                     ;
    localparam  int unsigned INST_RD_WIDTH          = $clog2(INST_READ_CHANNEL)         ;   
    localparam  int unsigned CREDIT_ADD_FILL        = 2*FETCH_WRITE_CHANNEL             ;    
    localparam  int unsigned CREDIT_CAL_WIDTH       = $clog2(CREDIT_ADD_FILL) + 1       ;    
    localparam  int unsigned CREDIT_CNT_WIDTH       = $clog2(DEPTH) + 1                 ;    

    //##############################################
    // logic 
    //##############################################
    logic                               wr_en                   ;
    logic                               pre_wr_en               ;   
    logic                               wr_ptr_over             ;
    logic                               pre_wr_ptr_over         ;
    logic                               rd_ptr_over             ;
    logic                               pc_lock                 ;

    logic [$clog2(DEPTH)-1      :0]     rd_ptr                  ;
    logic [$clog2(DEPTH)-1      :0]     rd_ptr_nxt              ;
    logic [$clog2(DEPTH)-1      :0]     wr_ptr                  ;
    logic [$clog2(DEPTH)-1      :0]     pre_wr_ptr              ;
    logic [$clog2(DEPTH)-1      :0]     pre_wr_ptr_reg          ;
    logic [$clog2(DEPTH)-1      :0]     wr_ptr_nxt              ;
    logic [$clog2(DEPTH)-1      :0]     pre_wr_ptr_nxt          ;
    logic [DEPTH_VECTOR_WIDTH-1 :0]     mem_wr_data_lsb         ;
    logic [CREDIT_CNT_WIDTH-1   :0]     crdt_cnt                ;
    logic [CREDIT_CNT_WIDTH-1   :0]     credit_calculate        ;
    logic [CREDIT_CNT_WIDTH-1   :0]     credit_residue          ;
    logic [DEPTH-1              :0]     v_pld_en                ;
    logic [INST_READ_CHANNEL-1  :0]     v_ack_en                ;

    logic [CREDIT_CAL_WIDTH-1   :0]     v_credit_sub      [INST_READ_CHANNEL-1:0]    ;
    logic [4                    :0]     v_opcode          [INST_READ_CHANNEL-1:0]    ;
    logic [RD_PTR_CAL_WIDTH-1   :0]     v_rd_ptr_add      [INST_READ_CHANNEL-1:0]    ;
    logic [WR_PTR_CAL_WIDTH-1   :0]     v_inst_num        [DEPTH-1            :0]    ;
    logic [15                   :0]     v_pld_mem         [DEPTH-1            :0]    ;
    logic [ADDR_WIDTH-1         :0]     v_inst_pc         [DEPTH-1            :0]    ;
    //##############################################
    // credit
    //##############################################

    // fetch_nxt_vld
    assign credit_residue   = DEPTH - crdt_cnt;
    assign fetch_nxt_vld   = (credit_residue>fetch_nxt_num) | clear;
    // fetch mem data num
    assign credit_calculate = (fetch_nxt_vld & fetch_nxt_rdy) ? (fetch_nxt_num - v_credit_sub[INST_READ_CHANNEL-1]) : (0 - v_credit_sub[INST_READ_CHANNEL-1]);

    // rd data num
    generate
        for (genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin :CREDIT_GEN
            assign v_ack_en[i] = v_ack_vld[i] & v_ack_rdy[i];
            if(i==0)begin : CREDIT_0_GEN
                always_comb begin 
                    if(v_ack_vld[i] & v_ack_rdy[i])begin
                        if(v_ack_pld[i][1:0] == 2'b11)begin
                            v_credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}} + 2'b10;
                        end
                        else begin
                            v_credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}} + 2'b01;
                        end
                    end
                    else begin
                        v_credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}};
                    end
                end
            end
            else begin : CREDIT_NEQ0_GEN
                always_comb begin 
                    if(v_ack_vld[i] & v_ack_rdy[i])begin
                        if(v_ack_pld[i][1:0] == 2'b11)begin
                            v_credit_sub[i] = v_credit_sub[i-1] + 2'b10;
                        end
                        else begin
                            v_credit_sub[i] = v_credit_sub[i-1] + 2'b01;
                        end
                    end
                    else begin
                        v_credit_sub[i] = v_credit_sub[i-1];
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin 
        if(~rst_n)      crdt_cnt <= {CREDIT_CNT_WIDTH{1'b0}};
        else if(clear)  crdt_cnt <= fetch_nxt_num;
        else if((fetch_nxt_vld & fetch_nxt_rdy) | (|v_ack_en))  crdt_cnt <= crdt_cnt + credit_calculate;
    end

    //##############################################
    // pre allocate , entry id/pc
    //##############################################

    assign pre_wr_en = fetch_nxt_vld & fetch_nxt_rdy ;
    assign mem_req_entry_id = pre_wr_ptr;
    // fetch mem data num
    always_comb begin
        if(clear)begin
            pre_wr_ptr_nxt = fetch_nxt_num;
        end
        else if(pre_wr_en)begin
            pre_wr_ptr_nxt = pre_wr_ptr + fetch_nxt_num;
        end
        else begin
            pre_wr_ptr_nxt = pre_wr_ptr;
        end
    end

    assign pre_wr_ptr = clear ? 0 : pre_wr_ptr_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  pre_wr_ptr_reg <= 0;
        else if(pre_wr_en | clear)  pre_wr_ptr_reg <= pre_wr_ptr_nxt;
    end

    //##############################################
    // write ptr
    //############################################## 
    assign wr_en        = mem_ack_vld;
    assign wr_ptr       = mem_ack_entry_id;
    assign wr_ptr_nxt   = wr_ptr + v_inst_num[mem_ack_entry_id];

    //##############################################
    // enerty
    //############################################## 

    // for wr ptr
    assign wr_ptr_over = wr_ptr_nxt<wr_ptr  ;
    assign pre_wr_ptr_over = pre_wr_ptr_nxt<pre_wr_ptr  ;

    assign mem_wr_data_lsb = 16*v_inst_pc[mem_ack_entry_id][FETCH_WR_WIDTH+1 : 1];
    // for rd ptr
    assign rd_ptr_over = rd_ptr_nxt<rd_ptr  ;

    // enerty
    generate for(genvar i=0; i<DEPTH; i=i+1) begin
        // pre write ----------------------------------------------------------------------------------
        // inst num
        always_ff @(posedge clk or negedge rst_n) begin : INSTRUCTION_NUM
            if(~rst_n)begin
                v_inst_num[i] <= {WR_PTR_CAL_WIDTH{1'b0}};
            end
            else if(i == pre_wr_ptr) begin
                v_inst_num[i] <= fetch_nxt_num;             
            end
        end

        // v_inst_pc   half word
        always_ff @(posedge clk or negedge rst_n) begin : INSTRUCTION_PC
            if(~rst_n)begin
                v_inst_pc[i] <= 32'b0;
            end
            else begin
                if(pre_wr_en) begin
                    if((i>=pre_wr_ptr) && ((i<pre_wr_ptr_nxt) || pre_wr_ptr_over))begin
                        v_inst_pc[i] <= fetch_nxt_pc + 2*(i-pre_wr_ptr);
                    end
                    else if(pre_wr_ptr_over && ((i+DEPTH)<{pre_wr_ptr_over,pre_wr_ptr_nxt}))begin
                        v_inst_pc[i] <= fetch_nxt_pc + 2*fetch_nxt_num - 2*(pre_wr_ptr_nxt-i);
                    end
                end
            end
        end

        // write data ---------------------------------------------------------------------------------
        // mem pld enable 
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)                                 v_pld_en[i] <= 1'b0;
            else if(clear)                             v_pld_en[i] <= 1'b0;
            // support partial write
            else if ( wr_en && ((i>=wr_ptr) && (i<wr_ptr_nxt)) ||  (wr_ptr_over && ((i>=wr_ptr) || (i+DEPTH)<{wr_ptr_over,wr_ptr_nxt})) )  begin
                v_pld_en[i] <= 1'b1;
            end
            // read
            else if ( |v_ack_en && ((i>=rd_ptr) && (i<rd_ptr_nxt)) ||  (rd_ptr_over && ((i>=rd_ptr) || (i+DEPTH)<{rd_ptr_over,rd_ptr_nxt})) )  begin
                v_pld_en[i] <= 1'b0;
            end
        end
        // data in mem   

        always_ff @(posedge clk or negedge rst_n) begin 
            if(~rst_n)begin
                v_pld_mem[i] <= 16'b0;
            end
            else begin
                if(wr_en) begin
                    if((i>=wr_ptr) && ((i<wr_ptr_nxt) || wr_ptr_over))begin
                        v_pld_mem[i] <= mem_ack_pld[FETCH_DATA_WIDTH'(mem_wr_data_lsb+16*(i-wr_ptr))+:16];
                    end
                    else if(wr_ptr_over && ((i+DEPTH)<{wr_ptr_over,wr_ptr_nxt}))begin
                        v_pld_mem[i] <= mem_ack_pld[FETCH_DATA_WIDTH'(mem_wr_data_lsb+16*(i+DEPTH-wr_ptr))+:16];
                    end
                end
            end
        end
    end endgenerate

    //##############################################
    // read ptr
    //##############################################

    assign rd_ptr_nxt = rd_ptr + v_rd_ptr_add[INST_READ_CHANNEL-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          rd_ptr <= 0;
        else if(clear)      rd_ptr <= 0;
        else if(|v_ack_en)  rd_ptr <= rd_ptr_nxt;
    end


    //##############################################
    // Output mux
    //##############################################

    generate
        for(genvar j=0;j<INST_READ_CHANNEL;j=j+1)begin :READ_CHANNLE_GEN
            // rpt add num
            if(j==0)begin :READ_CHANNLE_0_GEN
                always_comb begin 
                    if(v_ack_vld[j]&v_ack_rdy[j])begin
                        if(v_ack_pld[j][1:0]==2'b11)  v_rd_ptr_add[j] = 2;
                        else                          v_rd_ptr_add[j] = 1;
                    end
                    else                              v_rd_ptr_add[j] = 0;
                end 
            end
            else begin : READ_CHANNLE_NEQ0_GEN
                always_comb begin 
                    if(v_ack_vld[j]&v_ack_rdy[j])begin
                        if(v_ack_pld[j][1:0]==2'b11)  v_rd_ptr_add[j] = v_rd_ptr_add[j-1]+2;
                        else                          v_rd_ptr_add[j] = v_rd_ptr_add[j-1]+1;
                    end
                    else                              v_rd_ptr_add[j] = v_rd_ptr_add[j-1];
                end
            end
            //ack pld  data/pc
            if(j==0)begin:FETCH_QUEUE_ACK_PLD
                assign v_ack_pld[j] = {v_pld_mem[DEPTH_WIDTH'(rd_ptr+1)],v_pld_mem[rd_ptr]};
                assign v_ack_pld_pc[j] = v_inst_pc[rd_ptr];
            end
            else begin : FETCH_QUEUE_ACK_PLD_NORMAL
                assign v_ack_pld[j] = {v_pld_mem[DEPTH_WIDTH'(rd_ptr+v_rd_ptr_add[j-1]+1)],v_pld_mem[DEPTH_WIDTH'(rd_ptr+v_rd_ptr_add[j-1])]};
                assign v_ack_pld_pc[j] = v_inst_pc[DEPTH_WIDTH'(rd_ptr+v_rd_ptr_add[j-1])];
            end

            //ack_vld
            assign v_opcode[j] = v_ack_pld[j]`INST_FIELD_OPCODE; 
            if(j==0)begin
                always_comb begin:FETCH_PC_LOCK
                    // cycle lock
                    if(~pc_lock)begin       
                        // according to pld[1:0] && mem remainder data enable, confirm ack vld        
                        if(v_pld_en[rd_ptr])
                            if(v_ack_pld[j][1:0]!=2'b11)  begin
                                v_ack_vld[j] = 1'b1;
                            end
                            else if(v_pld_en[DEPTH_WIDTH'(rd_ptr+1)])begin
                                v_ack_vld[j] = 1'b1;
                            end
                            else begin
                                v_ack_vld[j] = 1'b0;
                            end
                        else begin
                            v_ack_vld[j] = 1'b0;
                        end    
                    end 
                    else begin
                        v_ack_vld[j] = 1'b0;
                    end
                end
            end
            else begin
                always_comb begin:FETCH_PC_LOCK_2
                    // cycle lock
                    if(~pc_lock)begin       
                        // according to pld[1:0] && mem remainder data enable, confirm ack vld        
                        if(v_pld_en[DEPTH_WIDTH'(rd_ptr+v_rd_ptr_add[j-1])])
                            if(v_ack_pld[j][1:0]!=2'b11)  begin
                                v_ack_vld[j] = 1'b1;
                            end
                            else if(v_pld_en[DEPTH_WIDTH'(rd_ptr+v_rd_ptr_add[j-1]+1)])begin
                                v_ack_vld[j] = 1'b1;
                            end
                            else begin
                                v_ack_vld[j] = 1'b0;
                            end
                        else begin
                            v_ack_vld[j] = 1'b0;
                        end
                    end
                    else begin
                        v_ack_vld[j] = 1'b0;
                    end
                end
            end
        end
    endgenerate


    //##############################################
    // pc_lock    cycle
    //##############################################
    assign pc_lock = cancel_en;
    // always_ff @(posedge clk or negedge rst_n) begin
    //     if(~rst_n)                  pc_lock <= 1'b0                 ;
    //     else if(pc_release_en)      pc_lock <= 1'b0                 ;
    //     else if(|v_pc_lock_comb)    pc_lock <= 1'b1                 ;
    // end


endmodule