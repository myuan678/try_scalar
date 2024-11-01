module toy_imem_model #(
    parameter string            ARGPARSE_KEY    = "HEX" ,
    parameter integer unsigned  ALLOW_NO_HEX    = 1     ,
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32    ,
    parameter integer unsigned  FETCH_SB_WIDTH  = 10    ,
    parameter integer unsigned  OFFSET_WIDTH    = 0
) (
    input  logic                     clk         ,
    input  logic                     en          ,
    input  logic [ADDR_WIDTH-1:0]    addr        ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    input  logic [FETCH_SB_WIDTH-1:0]req_send_back,
    output logic [FETCH_SB_WIDTH-1:0]ack_send_back,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    // input  logic [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input  logic                     wr_en       
);

    //logic [DATA_WIDTH-1:0] mem [0:1<<10-1];
    typedef logic [31:0] logic_32;
    typedef logic [ADDR_WIDTH-1:0]    logic_addr   ;
    typedef logic [DATA_WIDTH-1:0]    logic_data   ;


    logic_data              memory[logic_addr]    ;
    logic_data              tmp_data              ;
    string                  arg_parse_str         ;
    string                  code_path             ;

    function logic_data read_memory(logic_addr address);
        logic_data data;

        if (memory.exists(address)) begin
            data = memory[address];
        end else begin
            memory[address] = 'b0;
            data = 'b0; 
        end

        for (int i = 0; i < $bits(data); i++) begin
            if (data[i] === 1'bx) begin
                data[i] = 1'b0;
            end
        end

        return data;
    endfunction

    function logic_data read_non_aligned(logic_addr address);
        logic_data data_part1, data_part2;
        logic_data result;
        automatic int aligned_address = address >> OFFSET_WIDTH;
        automatic int offset = address & {OFFSET_WIDTH{1'b1}};
        
        // Fetch two consecutive memory blocks
        data_part1 = read_memory(aligned_address);
        data_part2 = read_memory(aligned_address + 1);
        
        // Handle concatenation based on the offset
        if (offset != 0) begin
            result = (data_part2 << (DATA_WIDTH - offset * 16)) | (data_part1 >> (offset * 16));
        end else begin
            result = data_part1; // No offset, aligned read
        end
        
        return result;
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
                tmp_data = wr_data;
                memory[addr] <= tmp_data;
            end
        end
    end

    // memory read handler =========================================================
    initial begin
        forever begin
            @(posedge clk)            
            if(en && ~wr_en) begin 
                rd_data <= read_non_aligned(addr);
                //rd_data <= read_memory(addr);
            end
            ack_send_back <= req_send_back;
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
                        $display("[%s][rd] %h : %h", ARGPARSE_KEY, addr, read_non_aligned(addr) );
            end
        end
    end


    // `ifdef TOY_SIM
    //     initial begin
    //         forever begin
    //             @(posedge clk)
    //             if(ack_send_back[0])begin
    //                 $display("itcm rd enable!!!");
    //                 $display("itcm align addr is [%h] offset[%h]", (addr>>OFFSET_WIDTH), (addr & {OFFSET_WIDTH{1'b1}}));
    //                 $display("itcm rdata 0 is [%h]", read_memory((addr>>OFFSET_WIDTH)));
    //                 $display("itcm rdata 1 is [%h]", read_memory((addr>>OFFSET_WIDTH)+1));
    //                 $display("itcm rdata all is [%h]", read_non_aligned(addr));
    //                 $display("itcm id is   [%h]", req_send_back[FETCH_SB_WIDTH-1:1]);
    //             end
    //         end
    //     end

    // `endif


endmodule