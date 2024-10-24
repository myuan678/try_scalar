module toy_bpu_filter
    import toy_pack::*;
    #(
        localparam  int unsigned FETCH_DATA_WIDTH = ADDR_WIDTH*FETCH_WRITE_CHANNEL
    )(
        input logic                                  clk,
        input logic                                  rst_n,

        // BTFIFO ==========================================
        output logic                                 btfifo_rdy,
        input  logic                                 btfifo_vld,
        input  bpu_pkg                               btfifo_pld,

        // ROB =============================================
        output logic                                 rob_rdy,
        input  logic                                 rob_vld,
        input  logic [FETCH_DATA_WIDTH-1:0]          rob_pld,

        // RAS =============================================
        output logic                                 ras_req_vld,
        output ras_pkg                               ras_req_pld,

        // Fetch Queue =====================================
        input  logic                                 fetch_queue_rdy,
        output logic                                 fetch_queue_vld,
        output fetch_queue_pkg                       fetch_queue_pld [FILTER_CHANNEL-1:0],
        output logic           [FILTER_CHANNEL-1:0]  fetch_queue_en,

        // FE Controller ===================================
        input  logic                                 fe_ctrl_be_chgflw,
        input  logic                                 fe_ctrl_ras_chgflw,
        input  bpu_pkg                               fe_ctrl_ras_pld,
        output logic                                 fe_ctrl_enqueue,
        output logic   [ADDR_WIDTH-1:0]              fe_ctrl_enqueue_pld
    );

    localparam INST_HALFWORD = INST_WIDTH_32/2;

    logic [INST_HALFWORD-1:0]           v_inst_halfword    [FILTER_CHANNEL:0];
    logic [INST_WIDTH_32-1:0]           v_inst_predec      [FILTER_CHANNEL-1:0];
    logic [ADDR_WIDTH-1:0]              v_inst_pc          [FILTER_CHANNEL-1:0];
    logic [ADDR_WIDTH-1:0]              v_inst_pc_nxt      [FILTER_CHANNEL:0];
    logic [FILTER_CHANNEL-1:0]          v_inst_en;
    logic [$clog2(FILTER_CHANNEL)-1:0]  v_inst_ptr_add     [FILTER_CHANNEL-1:0];
    logic [INST_WIDTH_32-1:0]           last_inst;
    logic                               is_call;
    logic                               is_ret;
    // logic                         is_cext;
    logic [BPU_OFFSET_WIDTH:0]          full_offset;
    logic [INST_HALFWORD-1:0]           last_half_inst_buf;
    logic [ADDR_WIDTH-1:0]              last_pc;
    logic                               last_en;
    logic [FILTER_CHANNEL-1:0]          v_last_en;

    logic [ADDR_WIDTH-1:0]              real_tgt_pc;


    assign full_offset           = (btfifo_pld.offset<<1) + (btfifo_pld.is_cext ? (btfifo_pld.carry) : 0);
    assign real_tgt_pc           = fe_ctrl_ras_chgflw ? fe_ctrl_ras_pld.tgt_pc : btfifo_pld.tgt_pc;

    // to other module
    assign btfifo_rdy            = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;
    assign rob_rdy               = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;

    assign ras_req_vld           = rob_vld && btfifo_vld && fetch_queue_rdy && ~(|v_last_en);
    assign ras_req_pld.inst_type = {is_ret, is_call};
    assign ras_req_pld.is_cext   = btfifo_pld.is_cext;
    assign ras_req_pld.carry     = btfifo_pld.carry;
    assign ras_req_pld.offset    = btfifo_pld.offset;
    assign ras_req_pld.pred_pc   = last_en ? last_pc : btfifo_pld.pred_pc;
    assign ras_req_pld.pc        = btfifo_pld.pred_pc + full_offset*2;
    assign ras_req_pld.tgt_pc    = btfifo_pld.tgt_pc;
    assign ras_req_pld.taken     = btfifo_pld.taken;

    assign fetch_queue_vld       = rob_vld && btfifo_vld && ~fe_ctrl_be_chgflw;
    assign fetch_queue_en        = v_inst_en;
    generate
        for (genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_FQ
            assign fetch_queue_pld[i].inst                  = v_inst_predec[i];
            assign fetch_queue_pld[i].bypass.is_call        = is_call;
            assign fetch_queue_pld[i].bypass.is_ret         = is_ret;
            assign fetch_queue_pld[i].bypass.pc             = v_inst_pc[i];
            assign fetch_queue_pld[i].bypass.bypass.carry   = btfifo_pld.is_cext;
            assign fetch_queue_pld[i].bypass.bypass.is_cext = btfifo_pld.carry;
            assign fetch_queue_pld[i].bypass.bypass.pred_pc = last_en ? last_pc : btfifo_pld.pred_pc;
            assign fetch_queue_pld[i].bypass.bypass.taken   = btfifo_pld.taken;
            assign fetch_queue_pld[i].bypass.bypass.tgt_pc  = v_inst_pc_nxt[i+1];
            assign fetch_queue_pld[i].bypass.bypass.offset  = btfifo_pld.offset;
        end
    endgenerate

    assign fe_ctrl_enqueue       = rob_vld && btfifo_vld && fetch_queue_rdy && ~fe_ctrl_be_chgflw;
    assign fe_ctrl_enqueue_pld   = btfifo_pld.pred_pc;

    // generate halfword
    generate
        for(genvar i = 0; i < FILTER_CHANNEL+1; i=i+1) begin: GEN_HALF
            if (i==FILTER_CHANNEL) assign v_inst_halfword[i] = {INST_HALFWORD{1'b0}};
            else                   assign v_inst_halfword[i] = rob_pld[i*INST_HALFWORD+:INST_HALFWORD];
        end
    endgenerate

    // pre-decode
    assign v_inst_pc_nxt[FILTER_CHANNEL] = real_tgt_pc;

    generate
        for(genvar i = 0; i < FILTER_CHANNEL; i=i+1) begin: GEN_CHANNEL
            if (i==0) begin
                assign v_inst_ptr_add[i] = 0;
                assign v_inst_pc[i]      = last_en ? last_pc : btfifo_pld.pred_pc;
                assign v_last_en[i]      = 0;
            end
            else if (i==1) begin
                assign v_inst_ptr_add[i] = last_en ? ((full_offset > v_inst_ptr_add[i-1])) : (((full_offset > v_inst_ptr_add[i-1])) ? (v_inst_halfword[0][1:0]==2'b11 ? 2 : 1) : 0);
                assign v_inst_pc[i]      = btfifo_pld.pred_pc + v_inst_ptr_add[i]*2;
                assign v_last_en[i]      = 0;
            end
            else begin
                assign v_inst_ptr_add[i] = (full_offset > v_inst_ptr_add[i-1])&&(v_inst_ptr_add[i-1]!=0) ? (v_inst_halfword[v_inst_ptr_add[i-1]][1:0]==2'b11 ? v_inst_ptr_add[i-1] + 2 : v_inst_ptr_add[i-1] + 1) : 0;
                assign v_inst_pc[i]      = v_inst_pc[i-1] + (v_inst_halfword[v_inst_ptr_add[i-1]][1:0]==2'b11 ? 2 : 1)*2;
                assign v_last_en[i]      = (v_inst_ptr_add[i]=={($clog2(FILTER_CHANNEL)){1'b1}}) && (v_inst_halfword[FILTER_CHANNEL-1][1:0]==2'b11);
            end

            if (i==0) begin
                assign v_inst_en[i]      = 1'b1;
                assign v_inst_pc_nxt[i]  = v_inst_pc[i];
                assign v_inst_predec[i]  = last_en ? {v_inst_halfword[v_inst_ptr_add[i]], last_half_inst_buf} : {v_inst_halfword[v_inst_ptr_add[i]+1], v_inst_halfword[v_inst_ptr_add[i]]};
            end
            else begin
                assign v_inst_en[i]      = |v_inst_ptr_add[i] && ~v_last_en[i];
                assign v_inst_pc_nxt[i]  = (v_inst_en[i]||(v_last_en[i]&&~btfifo_pld.taken)) ? v_inst_pc[i] : real_tgt_pc;
                assign v_inst_predec[i]  = {v_inst_halfword[v_inst_ptr_add[i]+1], v_inst_halfword[v_inst_ptr_add[i]]};
            end
        end
    endgenerate


    // for last offset but full inst
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                   last_en <= 1'b0;
        else if(fe_ctrl_be_chgflw)                   last_en <= 1'b0;
        else if(fetch_queue_rdy&&fetch_queue_vld) begin
            if(|v_last_en && ~btfifo_pld.taken)      last_en <= 1'b1;
            else                                     last_en <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  last_half_inst_buf <= {INST_HALFWORD{1'b0}};
        else if(fe_ctrl_be_chgflw)  last_half_inst_buf <= {INST_HALFWORD{1'b0}};
        else                        last_half_inst_buf <= v_inst_halfword[FILTER_CHANNEL-1];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  last_pc <= {ADDR_WIDTH{1'b0}};
        else if(fe_ctrl_be_chgflw)  last_pc <= {ADDR_WIDTH{1'b0}};
        else                        last_pc <= btfifo_pld.pred_pc + ((FILTER_CHANNEL-1)<<1);
    end


    // to ras
    // call
    // 1. jalr: rd == x1 or rd == x5;
    // 2. jal : rd == x1 or rd == x5;
    // 3. c.jalr
    // ret
    // 1. jalr: rs1 == x1 or rs1 == x5 and rs1!=rd;
    // 2. c.jr: rs1 ==x1 or rs1 == x5;
    // 3. c.jalr: rs1 == x5

    assign last_inst = {v_inst_halfword[full_offset+1], v_inst_halfword[full_offset]};

    assign is_call = (({last_inst[14:12],last_inst[6:0]} == 10'b000_1100111) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101))) //jalr
    || ((last_inst[6:0] == 7'b1101111) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101)))                                       //jal
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1001_00000_10) && (last_inst[11:7] != 5'b0));                                                   //c.jalr

    assign is_ret  = (({last_inst[14:12],last_inst[6:0]} == 10'b000_1100111) && (last_inst[11:7] != last_inst[19:15]) && ((last_inst[19:15] == 5'b00001) || (last_inst[19:15] == 5'b00101)) && (last_inst[31:20] == 12'b0)) //jalr
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1000_00000_10) && ((last_inst[11:7] == 5'b00001) || (last_inst[11:7] == 5'b00101)) && (last_inst[11:7] != 5'b00000))                                                      //jalr
    || (({last_inst[15:12],last_inst[6:0]} == 11'b1001_00000_10) && (last_inst[11:7] == 5'b00101));                                                                                                                         //c.jalr

endmodule 