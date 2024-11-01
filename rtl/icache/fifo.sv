module fifo#(
    parameter integer unsigned DATA_WIDTH=8,
    parameter integer unsigned ADDR_WIDTH=2
)(
    input logic                    clk      ,
    input logic                    rst_n    ,
    input logic                    wr_ena   ,
    input logic                    rd_ena   ,
    input logic  [DATA_WIDTH-1:0]  din      ,
    output logic [DATA_WIDTH-1:0]  dout     ,
    output logic                   full     ,
    output logic                   empty
);

logic [DATA_WIDTH-1:0] fifo_mem [ADDR_WIDTH-1:0]  ;
logic [ADDR_WIDTH:0]   wr_ptr                     ;
logic [ADDR_WIDTH:0]   rd_ptr                     ;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                wr_ptr <= {ADDR_WIDTH{1'b0}};
    else if(wr_ena && !full)  wr_ptr <= wr_ptr + 1'b1     ;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)                rd_ptr <= {ADDR_WIDTH{1'b0}};
    else if(rd_ena && !empty) rd_ptr <= rd_ptr + 1'b1     ;
end

integer i ;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<ADDR_WIDTH;i++) begin
            fifo_mem[i] <= {DATA_WIDTH{1'b0}};
        end
    end 
    else if(wr_ena && !full)        fifo_mem[wr_ptr] <= din;
end

assign dout  = fifo_mem[rd_ptr]                                                                                ;
assign empty = wr_ptr == rd_ptr                                                                                ;
assign full  = (wr_ptr[ADDR_WIDTH] !== rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

endmodule 