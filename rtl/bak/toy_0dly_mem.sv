
module toy_0dly_mem #(
    parameter integer unsigned ADDR_WIDTH = 32,
    parameter integer unsigned DATA_WIDTH = 32
) (
    input                       clk         ,

    input   [ADDR_WIDTH-1:0]    addr        ,
    output  [DATA_WIDTH-1:0]    rd_data     ,
    input   [DATA_WIDTH-1:0]    wr_data     ,
    input   [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input                       wr_en       
);


    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    assign rd_data = mem[addr];

    always_ff @(posedge clk) begin
        if(wr_en)
            $display("[DM][WR] %h : %d",addr,wr_data);
    end

    always_ff @(posedge clk) begin
        if(wr_en) begin
            if(wr_byte_en[0]) mem[addr][7 : 0] <= wr_data[7 : 0];
            if(wr_byte_en[1]) mem[addr][15: 8] <= wr_data[15: 8];
            if(wr_byte_en[2]) mem[addr][23:16] <= wr_data[23:16];
            if(wr_byte_en[3]) mem[addr][31:24] <= wr_data[31:24];
        end
    end

endmodule