

module toy_fecth2
    import toy_pack::*;
(
    input  logic                      clk                     ,
    input  logic                      rst_n                   ,

    // memory access
    input  logic                      mem_ack_vld             ,
    output logic                      mem_ack_rdy             ,
    input  logic [INST_WIDTH-1:0]     mem_ack_data            ,
    output logic [ADDR_WIDTH-1:0]     mem_req_addr            ,
    output logic                      mem_req_vld             ,
    input  logic                      mem_req_rdy             ,
    //output logic                      mem_en                  ,

    // pc update
    input logic                      trap_pc_release_en       ,
    input logic                      trap_pc_update_en        ,
    input logic [ADDR_WIDTH-1:0]     trap_pc_val              ,

    input logic                      jb_pc_release_en         ,
    input logic                      jb_pc_update_en          ,
    input logic [ADDR_WIDTH-1:0]     jb_pc_val                ,


    // fetch to exec
    output logic                      instruction_vld         ,
    input  logic                      instruction_rdy         ,
    output logic [INST_WIDTH-1:0]     instruction_pld         ,
    output logic [ADDR_WIDTH-1:0]     instruction_pc          
);



    logic                       rst_lock        ;

    logic [4:0]                 opcode          ;
    logic [ADDR_WIDTH-1:0]      pc              ;
    logic                       pc_lock         ;
    logic                       fetch_jump_inst ;

    logic [INST_WIDTH-1:0]      instruction_buffer          ;
    logic [INST_WIDTH-1:0]      instruction_buffer_en       ;
    logic                       instruction_ready_to_go     ;
    //logic [INST_WIDTH-1:0]      inst_pld ;

    logic                       pc_release_en   ;
    logic                       pc_update_en    ;
    logic [ADDR_WIDTH-1:0]      pc_val          ;
    // pc update merge ==========================================================
    
    // trap and jb pc update will not valid at the same cycle.
    assign pc_release_en        = trap_pc_release_en    | jb_pc_release_en      ;
    assign pc_update_en         = trap_pc_update_en     | jb_pc_update_en       ;
    assign pc_val               = trap_pc_update_en ? trap_pc_val : jb_pc_val   ;



    assign mem_ack_rdy = 1'b1;



    //assign instruction_ready_to_go = instruction_vld && instruction_rdy;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)      rst_lock <= 1'b1;
        else            rst_lock <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      pc_lock <= 1'b0;
        else if(pc_release_en)                          pc_lock <= 1'b0;
        else if(fetch_jump_inst)                        pc_lock <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      pc      <= 32'h8000_0000        ;
        else if(pc_update_en)                           pc      <= pc_val               ;
        else if(instruction_vld && ~instruction_rdy)    pc      <= pc                   ;
        else if(mem_req_vld & mem_req_rdy)              pc      <= pc + 4               ; // coding style todo.
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      instruction_ready_to_go <= 1'b0;
        else if(pc_update_en)                           instruction_ready_to_go <= 1'b0;
        else                                            instruction_ready_to_go <= mem_req_vld & mem_req_rdy;
    end



    assign mem_req_vld  = (~pc_lock) && (~rst_lock) && (~instruction_buffer_en);
    //assign mem_req_addr     = {2'b0,pc[ADDR_WIDTH-1:2]} ;

    assign mem_req_addr     = pc;

    assign instruction_vld = (~pc_lock) && (~rst_lock) && instruction_ready_to_go       ;
    assign instruction_pld  = instruction_buffer_en ?  instruction_buffer : mem_ack_data    ;



    always_ff @(posedge clk) begin
        if(instruction_vld && ~instruction_rdy) instruction_buffer <= mem_ack_data;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      instruction_buffer_en <= 1'b0;
        else if(pc_update_en)                           instruction_buffer_en <= 1'b0;
        else if(instruction_vld && ~instruction_rdy)    instruction_buffer_en <= 1'b1;
        else if(instruction_vld && instruction_rdy)     instruction_buffer_en <= 1'b0;
    end


    always_ff @(posedge clk) begin
        if(instruction_vld && ~instruction_rdy) begin
        end
        else begin
            instruction_pc <= pc;
        end

    end


    assign opcode = instruction_pld`INST_FIELD_OPCODE;

    always_comb begin
        case(opcode)
        OPC_JAL             : fetch_jump_inst = instruction_vld && instruction_rdy;
        OPC_JALR            : fetch_jump_inst = instruction_vld && instruction_rdy;
        OPC_BRANCH          : fetch_jump_inst = instruction_vld && instruction_rdy;
        default             : fetch_jump_inst = 1'b0;
        endcase
    end


    `ifdef TOY_SIM
    import "DPI-C" function void toy_scalar_disasm(output string str, input int unsigned pc, int unsigned inst);
    logic [63:0] cycle;


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)  cycle <= 0;
        else        cycle <= cycle + 1;
    end

    initial begin
        string str;
        if($test$plusargs("PC")) begin
            forever begin
                @(posedge clk)
                if(instruction_vld && instruction_rdy) begin
                    toy_scalar_disasm(str, instruction_pc, instruction_pld);
                    $display("%s", str);
                end
            end
        end
    end

    initial begin
        if($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk)
                if(fetch_jump_inst)
                    $display("[fch][%0d] detect jump inst, lock pc.", cycle);
                if(pc_release_en)
                    $display("[fch][%0d] receive pc release.", cycle);
                if(pc_update_en)
                    $display("[fch][%0d] receive pc update, update to %0d.", cycle, pc_val);

                $display("[fch][%0d]pc[%h].", cycle, pc);

                if(instruction_vld && instruction_rdy) 
                    $display("[fch][%0d] send inst pc[%h] = %h", cycle, instruction_pc, instruction_pld);

                if(instruction_vld && (~instruction_rdy))  
                    $display("[fch][%0d] stall by dispatch, pc[%h] = %h",cycle, instruction_pc, instruction_pld);
            end
        end
    end
  
    
    initial begin
        forever begin
            @(posedge clk)
            if(instruction_vld && instruction_rdy && (opcode ==OPC_JALR)) begin
                $display("[J] current inst[%h]=%h, jalr to dest pc %h.", instruction_pc, instruction_pld, pc_val);
            end
            if(instruction_vld && instruction_rdy && (opcode ==OPC_JAL)) begin
                $display("[J] current inst[%h]=%h, jal to dest pc %h.", instruction_pc, instruction_pld, pc_val);
            end
        end
    end



    `endif

endmodule


    // @(posedge clk) begin
    //    if (instruction_vld && instruction_rdy) begin
    //        $display("pc: %d,instruction %b %h",pc,instruction_pld,instruction_pld);
    //        //$display("mem_req_addr: %d",mem_req_addr);
    //    end
    //end