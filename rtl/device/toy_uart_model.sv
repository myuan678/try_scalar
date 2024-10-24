
module uart_model
(
    input  logic            clk         ,

    input  logic            en          ,
    input  logic [9:0]      addr        ,
    output logic [31:0]     rd_data     ,
    input  logic [31:0]     wr_data     ,
    input  logic [3:0]      wr_byte_en  ,  
    input  logic            wr_en       
);

    string print_buffer ;
    string print_char   ;

    assign rd_data = 32'b0;

    initial begin
        @(posedge clk)
        if(en & wr_en) begin

            $sformat(print_char, "%c", wr_data[7:0]);
            if(print_char == "\n") begin
                $display("[PRINT] %s", print_buffer);
                print_buffer = "";
            end 
            else begin
                $sformat(print_buffer, "%s%s", print_buffer,print_char);
            end

        end
    end





endmodule