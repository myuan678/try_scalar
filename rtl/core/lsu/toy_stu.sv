module toy_stu 
    import toy_pack::*;
(
    input  logic                      clk               ,
    input  logic                      rst_n             ,

    input  logic                      s_store_vld       ,
    input  lsu_pkg                    s_store_pld       ,

    output stu_pkg                    m_store_pld       ,
    output logic                      m_store_vld       

);

    logic [2:0]             funct3      ;
    logic [REG_WIDTH-1:0]   raw_address ;
    // logic [4:0]             word_offset ;



    assign m_store_vld = s_store_vld ;
    assign funct3   = s_store_pld.inst_pld`INST_FIELD_FUNCT3         ;


//===================================================================
// memory access
//===================================================================

    assign raw_address                  = s_store_pld.reg_rs1_val + s_store_pld.inst_imm    ;
    // assign word_offset                  = raw_address[4:0]      ;
    // assign m_store_pld.mem_req_opcode   = TOY_BUS_WRITE         ;
    assign m_store_pld.mem_req_data     = s_store_pld.reg_rs2_val   ;
    assign m_store_pld.mem_req_addr     = raw_address           ;
    assign m_store_pld.inst_pc          = s_store_pld.inst_pc   ;
    assign m_store_pld.inst_id          = s_store_pld.inst_id   ;
    assign m_store_pld.lsid             = s_store_pld.lsid      ;
    assign m_store_pld.c_ext            = s_store_pld.c_ext     ;
    // assign m_store_pld.word_offset      = raw_address[4:0]      ;
    always_comb begin
        case(funct3) 
            F3_LB,F3_LBU:   m_store_pld.mem_req_strb = 4'h1     ;
            F3_LH,F3_LHU:   m_store_pld.mem_req_strb = 4'h3     ;
            F3_LW:          m_store_pld.mem_req_strb = 4'hf     ;
            default:        m_store_pld.mem_req_strb = 4'h0     ;
        endcase
    end




//===================================================================
// sim debug
//===================================================================





    // `ifdef TOY_SIM

    // logic [ADDR_WIDTH-1:0] mem_req_addr_dly;
    
    // logic                   is_store    ;

    // assign is_store = s_store_vld;
    // always_ff @(posedge clk) begin
    //     if(mem_req_vld & mem_req_rdy) mem_req_addr_dly <= mem_req_addr;
    // end


    // initial begin
    //     if($test$plusargs("DEBUG")) begin
    //         forever begin
    //             @(posedge clk)

    //             if(is_store) begin
    //                 $display("[lsu][st] receive a inst[%h] = [0x%h].",pc, instruction_pld); 
    //                 $display("[lsu][st] mem[0x%h] = %h = reg[%0d]", mem_req_addr, rs2_val, instruction_pld`INST_FIELD_RS2);
    //             end

    //             if(reg_wr_en) begin
    //                 if($isunknown(mem_ack_data))
    //                     $display("[lsu][ls] ERROR!!!! load x val from mem[%h]= %h.", mem_req_addr_dly, mem_ack_data);
    //                 $display("[lsu][ld] reg[%d] = %h, mem[%h]= %h", reg_index, reg_val, mem_req_addr_dly, mem_ack_data);
    //                 $display("[lsu][ld] mem data: %h.", mem_ack_data);
    //             end

    //             if(instruction_vld && instruction_rdy && ~is_store) begin
    //                 $display("[lsu][ld] receive a inst[%h] = [0x%h].",pc, instruction_pld); 
    //             end

    //         end
    //     end
    // end
    // `endif


endmodule


    //    if(opcode == OPC_AMO) begin
    //        if (instruction_pld[31:27] == AMOSC) begin
    //            if(sc_success)                      reg_val = 32'b0;
    //            else                                reg_val = 32'b1;
    //        end 
    //        else                                    reg_val = mem_ack_data;
    //    end
    //    else begin
    //        case(funct3_dly)
    //        F3_LB       : reg_val = {{24{shifted_rd_data[7]}}   ,   shifted_rd_data[7:0]    };
    //        F3_LBU      : reg_val = {24'b0                      ,   shifted_rd_data[7:0]    };
    //        F3_LH       : reg_val = {{16{shifted_rd_data[15]}}  ,   shifted_rd_data[15:0]   };
    //        F3_LHU      : reg_val = {16'b0                      ,   shifted_rd_data[15:0]   };
    //        F3_LW       : reg_val = mem_ack_data;
    //        default     : reg_val = mem_ack_data;
    //        endcase
    //    end
    //end 





    //always_ff @(posedge clk) begin
    //    reg_wr_en           <= (inst_rd_en & instruction_vld & instruction_rdy) | (~amo_store & instruction_vld & is_amo );
    //end 
