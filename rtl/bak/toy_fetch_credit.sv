module toy_fetch_credit 
    import toy_pack::*;
#(
    parameter   int unsigned DEPTH                  = 128

)(
    input   logic                           clk         ,
    input   logic                           rst_n       ,
    input   logic                           clear       ,

    output  logic                           req_vld     ,
    input   logic                           req_rdy     ,
    input   logic   [ADDR_WIDTH-1   :0]     fetch_addr  ,

    input   logic   [INST_READ_CHANNEL-1:0] ack_vld     ,
    input   logic   [INST_READ_CHANNEL-1:0] ack_rdy     ,
    input   logic   [INST_WIDTH-1   :0]     ack_pld     [INST_READ_CHANNEL-1:0]
);


    //##############################################
    // parameter
    //##############################################
    localparam  int unsigned FETCH_WR_WIDTH         = $clog2(FETCH_WRITE_CHANNEL)   ;
    localparam  int unsigned INST_RD_WIDTH          = $clog2(INST_READ_CHANNEL)     ;   
    localparam  int unsigned CREDIT_ADD_FILL        = 2*FETCH_WRITE_CHANNEL         ;    
    localparam  int unsigned CREDIT_CAL_WIDTH       = $clog2(CREDIT_ADD_FILL) + 1   ;    
    localparam  int unsigned CREDIT_CNT_WIDTH       = $clog2(DEPTH) + 1             ;    

    //##############################################
    // logic 
    //##############################################
    logic [CREDIT_CNT_WIDTH-1:0]        crdt_cnt            ;
    logic [CREDIT_CNT_WIDTH-1:0]        credit_calculate    ;
    logic [CREDIT_CNT_WIDTH-1:0]        credit_residue      ;
    logic [CREDIT_CAL_WIDTH-1:0]        credit_add          ;
    logic [INST_READ_CHANNEL-1:0]       rd_halfword         ;
    logic [CREDIT_CAL_WIDTH-1:0]        credit_sub  [INST_READ_CHANNEL-1:0];
    logic [INST_READ_CHANNEL-1:0]       ack_en              ;
    // req_vld
    assign credit_residue   = DEPTH - crdt_cnt;
    assign req_vld          =  (credit_residue>(CREDIT_ADD_FILL - fetch_addr[FETCH_WR_WIDTH+1 : 1])) | clear;
    // fetch mem data num
    assign credit_add = (req_vld & req_rdy) ? (CREDIT_ADD_FILL - fetch_addr[FETCH_WR_WIDTH+1 : 1]) : 0 ;
    assign credit_calculate = credit_add - credit_sub[INST_READ_CHANNEL-1];

    // rd data num
    generate
        for (genvar i = 0; i < INST_READ_CHANNEL; i=i+1) begin
            assign ack_en[i] = ack_vld[i] & ack_rdy[i];
            always_comb begin 
                if(i==0)begin
                    if(ack_vld[i] & ack_rdy[i])begin
                        if(ack_pld[i][1:0] == 2'b11)begin
                            credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}} + 2'b10;
                        end
                        else begin
                            credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}} + 2'b01;
                        end
                    end
                    else begin
                        credit_sub[i] = {CREDIT_CAL_WIDTH{1'b0}};
                    end
                end
                else begin
                    if(ack_vld[i] & ack_rdy[i])begin
                        if(ack_pld[i][1:0] == 2'b11)begin
                            credit_sub[i] = credit_sub[i-1] + 2'b10;
                        end
                        else begin
                            credit_sub[i] = credit_sub[i-1] + 2'b01;
                        end
                    end
                    else begin
                        credit_sub[i] = credit_sub[i-1];
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin 
        if(~rst_n)      crdt_cnt <= {CREDIT_CNT_WIDTH{1'b0}};
        else if(clear)  crdt_cnt <= credit_add;
        else if((req_vld & req_rdy) | (|ack_en))  crdt_cnt <= crdt_cnt + credit_calculate;
      
    end

endmodule 