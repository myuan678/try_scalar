module toy_mem_model_allude #(
    parameter string            ARGPARSE_KEY    = "HEX" ,
    parameter integer unsigned  ALLOW_NO_HEX    = 1     ,
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32
) (
    input  logic                     clk         ,

    input  logic                     en          ,
    input  logic [ADDR_WIDTH-1:0]    addr        ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    input  logic [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input  logic                     wr_en       
);

    //logic [DATA_WIDTH-1:0] mem [0:1<<10-1];

    typedef logic [ADDR_WIDTH-1:0]    logic_addr   ;
    typedef logic [DATA_WIDTH-1:0]    logic_data   ;


    logic_data              memory[logic_addr]    ;
    logic   [31:0]          tmp_data              ;
    string                  arg_parse_str         ;
    string                  code_path             ;

    function logic_data read_memory(logic_addr address);
        logic_data data;

        if (memory.exists(address)) begin
            data = memory[address];
        end else begin
            memory[address] = 'x;
            data = 'x; 
        end

        return data;
    endfunction





    initial begin
        $sformat(arg_parse_str, "%s=%%s", ARGPARSE_KEY);
        
        // memory initialize ===========================================================
        if($value$plusargs(arg_parse_str, code_path)) begin
            $readmemh(code_path, memory);
            if($test$plusargs("DEBUG")) begin
                $display("print memory first 10 row parse from arg %s:", ARGPARSE_KEY);
                for(int i=0;i<10;i++) begin
                    $display("memory row[%0d] = %h" , i, read_memory(i));
                end
            end
        end else begin
            if(ALLOW_NO_HEX!=0) begin
                if($test$plusargs("DEBUG"))
                    $info("Missing required parameter +%s",ARGPARSE_KEY);
            end
            else begin
                $error("Missing required parameter +%s",ARGPARSE_KEY);
                $finish;
            end
        end

        // memory write handler ========================================================
        forever begin
            @(posedge clk)
            if(wr_en && en) begin
                tmp_data = read_memory(addr);
                for( int i=0;i<DATA_WIDTH/8;i=i+1)begin
                    if(wr_byte_en[i]) tmp_data[8*i+:8] = wr_data[8*i+:8];
                end
                memory[addr] <= tmp_data;
            end
        end
    end


    // memory read handler =========================================================
    initial begin
        forever begin
            @(posedge clk)            
            if(en && ~wr_en) rd_data = read_memory(addr);
        end
    end




    initial begin
        if($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk)
                if(en)
                    if(wr_en)
                        $display("[%s][wr] %h : %h", ARGPARSE_KEY, addr, wr_data    );
                    else
                        $display("[%s][rd] %h : %h", ARGPARSE_KEY, addr, read_memory(addr) );
            end
        end
    end



endmodule