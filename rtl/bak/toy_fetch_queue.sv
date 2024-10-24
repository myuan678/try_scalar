

    //////////////////////////////////////////////////////////////////////////////////
    // Company: URBADASS.LTD
    // Engineer: zick
    // 
    // Create Date: 02/26/2023 09:01:54 PM
    // Design Name: sync fifo handshake
    // Module Name: sync_fifo
    // Project Name: sync fifo
    // Description: 
    //              a handshake based sync fifo for serialized data
    // Dependencies: 
    // 
    // Revision:
    //              Revision 0.01 - File Created
    // Additional Comments:
    // 
    //////////////////////////////////////////////////////////////////////////////////
    module toy_fetch_queue #(
        parameter   int unsigned DEPTH    = 8             ,
        parameter   type         PLD_TYPE = logic[32-1:0] ,  
        localparam  int unsigned AWIDTH   = $clog2(DEPTH)
    )(
        input   logic               clk    ,
        input   logic               rst_n  ,

        input   logic               clear  ,
        // Req
        input   logic               req_vld,
        output  logic               req_rdy,
        input   PLD_TYPE            req_pld,
        // ACK
        output  logic               ack_vld,
        input   logic               ack_rdy,
        output  PLD_TYPE            ack_pld
    );

    //=================================================================
    // Internal Signal
    //=================================================================
        PLD_TYPE                    pld_mem  [DEPTH-1:0];
        logic       [AWIDTH-1  :0]  wr_ptr              ;
        logic       [AWIDTH-1  :0]  rd_ptr              ;
        logic                       rd_en               ;
        logic                       wr_en               ;
        logic       [AWIDTH    :0]  fifo_cnt            ;
        logic                       fifo_full           ;
        logic                       fifo_empty          ;

    //=================================================================
    // WR/RD enable
    //=================================================================
        assign wr_en = req_vld && req_rdy;
        assign rd_en = ack_vld && ack_rdy;

    //=================================================================
    // depth counter
    //=================================================================
        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                fifo_cnt <= {AWIDTH+1{1'b0}};
            end
            else if(clear) begin
                fifo_cnt <= {AWIDTH+1{1'b0}};
            end
            else begin
                case ({rd_en, wr_en})
                    {1'b1, 1'b0}: fifo_cnt <= (AWIDTH+1)'(fifo_cnt - 1'b1); // read, old version vcs/xrun does not support type(fifo_cnt)'
                    {1'b0, 1'b1}: fifo_cnt <= (AWIDTH+1)'(fifo_cnt + 1'b1); // write 
                    default     : fifo_cnt <= fifo_cnt;        // no operation or read, write simultaneously
                endcase
            end
        end

    //=================================================================
    // Empty & Full
    //=================================================================
        assign fifo_empty = ~|fifo_cnt;
        assign fifo_full  = fifo_cnt == DEPTH;

    //=================================================================
    // Handshake
    //=================================================================
        assign ack_vld = ~fifo_empty;
        assign req_rdy = ~fifo_full;

    //=================================================================
    // WR/RD control
    //=================================================================
        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                wr_ptr <= {AWIDTH{1'b0}};
            end
            else if (clear) begin
                wr_ptr <= {AWIDTH{1'b0}};
            end
            else if (wr_en) begin
                if (wr_ptr < DEPTH-1)
                    wr_ptr <= AWIDTH'(wr_ptr + 1'b1);
                else 
                    wr_ptr <= {AWIDTH{1'b0}};
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                rd_ptr <= {AWIDTH{1'b0}};
            end
            else if (clear) begin
                rd_ptr <= {AWIDTH{1'b0}};
            end
            else if (rd_en) begin
                if (rd_ptr < DEPTH-1)
                    rd_ptr <= AWIDTH'(rd_ptr + 1'b1);
                else 
                    rd_ptr <= {AWIDTH{1'b0}};
            end
        end

    //=================================================================
    // Mem access
    //=================================================================
        always_ff @(posedge clk) begin
            if (wr_en) pld_mem[wr_ptr] <= req_pld;
        end
        assign ack_pld = pld_mem[rd_ptr];

    endmodule