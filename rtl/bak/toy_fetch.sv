

module toy_fecth
    import toy_pack::*;
(
    input                       clk                     ,
    input                       rst_n                   ,

    // memory access
    output [ADDR_WIDTH-1:0]     mem_addr                ,
    input  [INST_WIDTH-1:0]     mem_data                ,

    // pc update
    input                       pc_release_en           ,
    input                       pc_update_en            ,
    input  [ADDR_WIDTH-1:0]     pc_val             ,

    // fetch to exec
    output                      instruction_vld         ,
    input                       instruction_rdy         ,
    output [INST_WIDTH-1:0]     instruction_pld         ,
    output [ADDR_WIDTH-1:0]     instruction_pc          
);

    logic                       rst_lock        ;

    logic [4:0]                 opcode          ;
    logic [ADDR_WIDTH-1:0]      pc              ;
    logic                       pc_lock         ;
    logic                       fetch_jump_inst ;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)      rst_lock <= 1'b1;
        else            rst_lock <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      pc_lock <= 1'b0;
        else if(fetch_jump_inst)                        pc_lock <= 1'b1;
        else if(pc_release_en)                          pc_lock <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        
        if(~rst_n)                                      pc      <= {ADDR_WIDTH{1'b0}}   ;
        else if(pc_update_en)                           pc      <= pc_val               ;
        else if(instruction_vld && instruction_rdy)     pc      <= pc + 4               ; // coding style todo.
    end

    always_ff @(posedge clk) begin
        if (instruction_vld && instruction_rdy) begin
            $display("pc: %d,instruction %b %h",pc,instruction_pld,instruction_pld);
            //$display("mem_addr: %d",mem_addr);
        end
    end


    assign instruction_vld = (~pc_lock) && (~rst_lock)      ;
    assign instruction_pld  = mem_data                      ;
    assign mem_addr         = {2'b0,pc[ADDR_WIDTH-1:2]}     ;
    assign instruction_pc   = pc                            ;


    assign opcode = instruction_pld`INST_FIELD_OPCODE;

    always_comb begin
        case(opcode)
        OPC_JAL             : fetch_jump_inst = 1'b1;
        OPC_JALR            : fetch_jump_inst = 1'b1;
        OPC_BRANCH          : fetch_jump_inst = 1'b1;
        default             : fetch_jump_inst = 1'b0;
        endcase
    end

endmodule