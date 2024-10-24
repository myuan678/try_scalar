


module toy_mem_model #(
    parameter string            ARGPARSE_KEY    = "HEX" ,
    parameter integer unsigned  ALLOW_NO_HEX    = 1     ,
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32    ,
    parameter integer unsigned  FETCH_SB_WIDTH  = 10    
) (
    input  logic                     clk         ,

    input  logic                     en          ,
    input  logic [ADDR_WIDTH-1:0]    addr        ,
    input  logic [FETCH_SB_WIDTH-1:0]req_send_back,
    output logic [FETCH_SB_WIDTH-1:0]ack_send_back,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    input  logic [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input  logic                     wr_en       
);

    //logic [DATA_WIDTH-1:0] mem [0:1<<10-1];
    typedef logic [31:0] logic_32;
    typedef logic [255:0] logic_256;

    logic_256            memory [logic_32]  ;
    logic   [DATA_WIDTH-1:0]            tmp_data                ;
    string                              arg_parse_str           ;
    string                              code_path               ;



    function logic_256 read_memory(logic_32 address);
        logic_256 data;

        if (memory.exists(address)) begin
            data = memory[address];
        end else begin
            memory[address] = 'd0;
            data = 'd0; 
        end

        return data;
    endfunction

    logic_32 memory_backdoor[logic_32];
    logic [DATA_WIDTH-1:0] memory_temp;
    initial begin
        @(posedge clk);
        @(posedge clk);

        for (int a=0;a<(memory_backdoor.size()+8);a=a+1)begin
            if(a%8==0)begin
                if((a+7)>memory_backdoor.size())begin
                    for(int b=0;b<8;b++)begin
                        if (memory_backdoor.exists(a+b))begin
                            memory_temp[b*32+:32] = memory_backdoor[a+b];
                        end
                        else begin
                            memory_temp[b*32+:32] = 32'h0;
                        end
                    end
                    memory[a/8] = memory_temp;
                end
                else begin
                    memory[a/8] = {memory_backdoor[a+7],memory_backdoor[a+6],memory_backdoor[a+5],memory_backdoor[a+4],memory_backdoor[a+3],memory_backdoor[a+2],memory_backdoor[a+1],memory_backdoor[a]};
                end
            end
        end
    end


    initial begin
        $sformat(arg_parse_str, "%s=%%s", ARGPARSE_KEY);
        
        // memory initialize ===========================================================
        if($value$plusargs(arg_parse_str, code_path)) begin
            $readmemh(code_path, memory_backdoor);
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
                // if(wr_byte_en[0]) tmp_data[7 : 0] = wr_data[7 : 0];
                // if(wr_byte_en[1]) tmp_data[15: 8] = wr_data[15: 8];
                // if(wr_byte_en[2]) tmp_data[23:16] = wr_data[23:16];
                // if(wr_byte_en[3]) tmp_data[31:24] = wr_data[31:24];
                memory[addr] <= tmp_data;
            end
        end
    end


    // memory read handler =========================================================
    initial begin
        forever begin
            @(posedge clk)            
            if(en && ~wr_en) begin
                rd_data <= read_memory(addr);
                ack_send_back <= req_send_back;
            end
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
                        $display("[%s][rd] %h : %h", ARGPARSE_KEY, addr, memory[addr]  );
            end
        end
    end



endmodule





