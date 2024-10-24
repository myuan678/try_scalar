

module tb;

    parameter integer unsigned  ADDR_WIDTH      = 32    ;
    parameter integer unsigned  DATA_WIDTH      = 32    ;

    logic                     clk           ;

    logic                     en            ;
    logic [ADDR_WIDTH-1:0]    addr          ;
    logic [DATA_WIDTH-1:0]    rd_data       ;
    logic [DATA_WIDTH-1:0]    wr_data       ;
    logic [DATA_WIDTH/8-1:0]  wr_byte_en    ;
    logic                     wr_en         ;

    toy_mem_model #(
        .ADDR_WIDTH   (ADDR_WIDTH   ),
        .DATA_WIDTH   (DATA_WIDTH   )) 
    u_mem(
        .clk         (clk         ),
        .en          (en          ),
        .addr        (addr        ),
        .rd_data     (rd_data     ),
        .wr_data     (wr_data     ),
        .wr_byte_en  (wr_byte_en  ),
        .wr_en       (wr_en       ));

    initial begin
        clk = 0;
        forever begin
            #1;
            clk = ~clk;
        end
    end

    initial begin
        #100;
        $finish;
    end


 

endmodule
