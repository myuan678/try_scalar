
module toy_1dly_mem #(
    parameter integer unsigned ADDR_WIDTH = 32,
    parameter integer unsigned DATA_WIDTH = 32
) (
    input  logic                     clk         ,

    input  logic                     en          ,
    input  logic [ADDR_WIDTH-1:0]    addr        ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    input  logic [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input  logic                     wr_en       
);


    logic [DATA_WIDTH-1:0] mem [0:4095];


    string code_path;

    initial begin

        if($value$plusargs("DATA_HEX=%s", code_path)) begin
            $readmemh(code_path, mem);
            $display("print data memory first 10 row:");
            for(int i=0;i<10;i++) begin
                $display("memory row[%0d] = %h" , i, mem[i]);
            end
        end else begin
            $info("Missing required parameter +DATA_HEX");
            //$error("Missing required parameter +DATA_HEX");
            //$finish;
        end

        forever begin
            @(posedge clk)
            if(wr_en && en) begin
                if(wr_byte_en[0]) mem[addr][7 : 0] <= wr_data[7 : 0];
                if(wr_byte_en[1]) mem[addr][15: 8] <= wr_data[15: 8];
                if(wr_byte_en[2]) mem[addr][23:16] <= wr_data[23:16];
                if(wr_byte_en[3]) mem[addr][31:24] <= wr_data[31:24];
            end
        end
    end






    always_ff @(posedge clk) begin
        if(en) rd_data <= mem[addr];
    end

    always_ff @(posedge clk) begin
        if(en)
            if(wr_en)
                $display("[dm][wr] %h : %h",addr,wr_data);
            else
                $display("[dm][rd] %h : %h",addr,mem[addr]);
    end


endmodule