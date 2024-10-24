module toy_bpu_ras
    import toy_pack::*;
    (
        input logic                          clk,
        input logic                          rst_n,

        // filter ==============================================
        input logic                          filter_vld,
        input ras_pkg                        filter_pld,

        // FE Controller =======================================
        input   logic                        fe_ctrl_flush,
        input   logic                        fe_ctrl_chgflw,
        input   ras_pkg                      fe_ctrl_chgflw_pld,
        output  bpu_pkg                      fe_ctrl_ras_pld,
        output  logic                        fe_ctrl_ras_chgflw
    );

    logic [ADDR_WIDTH-1:0]           ras_stack     [RAS_DEPTH-1:0];
    logic [ADDR_WIDTH-1:0]           rtu_stack     [RAS_DEPTH-1:0];

    logic [RAS_PTR_WIDTH:0]          top_ptr;
    logic [RAS_PTR_WIDTH:0]          btm_ptr;
    logic [RAS_PTR_WIDTH:0]          real_top_ptr;
    logic                            is_call;
    logic                            is_ret;
    logic [ADDR_WIDTH-1:0]           call_pc_nxt;
    logic [RAS_PTR_WIDTH:0]          rtu_top_ptr;
    logic [RAS_PTR_WIDTH:0]          rtu_btm_ptr;
    logic                            rtu_ret_en;
    logic                            rtu_call_en;
    logic [ADDR_WIDTH-1:0]           rtu_call_pc_nxt;

    logic                            stack_full;
    logic                            stack_empty;
    logic                            rtu_stack_full;
    logic                            rtu_stack_empty;

    logic                            stack_overflow;
    logic                            rtu_stack_overflow;
    logic [RAS_PTR_WIDTH:0]          rtu_top_ptr_next;
    logic                            update_top_ptr;
    logic [RAS_PTR_WIDTH:0]          top_ptr_next;


    // inst type: [0] call; [1] return
    assign fe_ctrl_ras_chgflw           = filter_vld && filter_pld.inst_type[1] && (ras_stack[real_top_ptr[RAS_PTR_WIDTH-1:0]] != filter_pld.tgt_pc) && !stack_empty;
    assign fe_ctrl_ras_pld.pred_pc      = filter_pld.pred_pc;
    assign fe_ctrl_ras_pld.offset       = filter_pld.offset;
    assign fe_ctrl_ras_pld.tgt_pc       = ras_stack[real_top_ptr[RAS_PTR_WIDTH-1:0]]&{ADDR_WIDTH{fe_ctrl_ras_chgflw}};
    assign fe_ctrl_ras_pld.taken        = filter_pld.taken;
    assign fe_ctrl_ras_pld.is_cext      = filter_pld.is_cext;
    assign fe_ctrl_ras_pld.carry        = filter_pld.carry;

    // commit pointer
    assign rtu_call_en                  = fe_ctrl_chgflw && fe_ctrl_chgflw_pld.inst_type[0];
    assign rtu_ret_en                   = fe_ctrl_chgflw && fe_ctrl_chgflw_pld.inst_type[1];

    // rtu pointer
    assign rtu_stack_full               = rtu_top_ptr == {~rtu_btm_ptr[RAS_PTR_WIDTH], rtu_btm_ptr[RAS_PTR_WIDTH-1:0]};
    assign rtu_stack_empty              = rtu_top_ptr == rtu_btm_ptr;
    assign rtu_stack_overflow           = rtu_stack_full && rtu_call_en;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          rtu_btm_ptr <= {RAS_PTR_WIDTH{1'b0}};
        else if(rtu_stack_overflow)         rtu_btm_ptr <= rtu_btm_ptr + 1'b1;
    end

    always_comb begin
        if(rtu_ret_en && ~rtu_stack_empty)  rtu_top_ptr_next = rtu_top_ptr - 1'b1;
        else if(rtu_call_en)                rtu_top_ptr_next = rtu_top_ptr + 1'b1;
        else                                rtu_top_ptr_next = rtu_top_ptr;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          rtu_top_ptr <= {RAS_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_chgflw)             rtu_top_ptr <= rtu_top_ptr_next;
    end

    // top pointer
    assign is_call                      = filter_vld && filter_pld.inst_type[0];
    assign is_ret                       = filter_vld && filter_pld.inst_type[1];
    assign stack_full                   = top_ptr == {~btm_ptr[RAS_PTR_WIDTH], btm_ptr[RAS_PTR_WIDTH-1:0]};
    assign stack_empty                  = top_ptr == btm_ptr;
    assign stack_overflow               = stack_full && is_call;
    assign real_top_ptr                 = top_ptr - 1'b1; // use reg to opt timing

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                   btm_ptr <= {RAS_PTR_WIDTH{1'b0}};
        else if(fe_ctrl_flush&&rtu_stack_overflow)   btm_ptr <= rtu_btm_ptr + 1'b1;
        else if(fe_ctrl_flush)                       btm_ptr <= rtu_btm_ptr;
        else if(stack_overflow)                      btm_ptr <= btm_ptr + 1'b1;
    end

    assign update_top_ptr = fe_ctrl_flush || is_call || (is_ret && ~stack_empty);

    always_comb begin
        if(fe_ctrl_flush)                            top_ptr_next  = rtu_top_ptr_next;
        else if(is_call)                             top_ptr_next  = top_ptr + 1'b1;
        else if(is_ret && ~stack_empty)              top_ptr_next  = top_ptr - 1'b1;
        else                                         top_ptr_next  = top_ptr;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                   top_ptr <= {RAS_PTR_WIDTH{1'b0}};
        else if(update_top_ptr)                      top_ptr <= top_ptr_next;
    end

    // update stack
    assign rtu_call_pc_nxt  = fe_ctrl_chgflw_pld.is_cext ? fe_ctrl_chgflw_pld.pc + 2 : fe_ctrl_chgflw_pld.pc + 4;
    assign call_pc_nxt      = filter_pld.is_cext ? filter_pld.pc + 2 : filter_pld.pc + 4;

    always_ff @(posedge clk) begin
        if(fe_ctrl_chgflw) begin
            if(fe_ctrl_chgflw && rtu_call_en)    rtu_stack[rtu_top_ptr[RAS_PTR_WIDTH-1:0]] <= rtu_call_pc_nxt;
        end
    end

    generate
        for(genvar i = 0; i < RAS_DEPTH; i=i+1) begin: GEN_RAS_STACK
            always_ff @(posedge clk) begin
                if (fe_ctrl_flush)  begin
                    if(rtu_call_en && (rtu_top_ptr[RAS_PTR_WIDTH-1:0]==i))  ras_stack[i] <= rtu_call_pc_nxt;
                    else                                                    ras_stack[i] <= rtu_stack[i];
                end
                else if (is_call&&(top_ptr[RAS_PTR_WIDTH-1:0]==i))          ras_stack[i] <= call_pc_nxt;
            end
        end
    endgenerate


endmodule