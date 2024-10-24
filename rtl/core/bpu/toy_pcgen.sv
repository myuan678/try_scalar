module toy_pcgen
    import toy_pack::*;
    (
        input logic                            clk,
        input logic                            rst_n,

        // frontend controller ============================================
        input  logic                           fe_ctrl_stall,
        input  logic                           fe_ctrl_chgflw_vld,
        input  bpu_pkg                         fe_ctrl_chgflw_pld,
        output logic                           fe_ctrl_chgflw_rdy,

        // rob prealloc ===================================================
        output logic                           rob_prealloc_req,
        input  logic [ROB_ENTRY_ID_WIDTH-1:0]  rob_prealloc_entry_id,

        // icache =========================================================
        output logic                           icache_req_vld,
        output logic [ROB_ENTRY_ID_WIDTH-1:0]  icache_req_entry_id,
        output logic [ADDR_WIDTH-1:0]          icache_req_addr,
        input  logic                           icache_req_rdy,

        // l0btb ==========================================================
        output logic                           pcgen_l0btb_vld,
        output logic [ADDR_WIDTH-1:0]          pcgen_l0btb_pc,

        // l1btb ==========================================================
        output logic                           pcgen_btb_vld,
        output logic [ADDR_WIDTH-1:0]          pcgen_btb_pc,

        // tage ===========================================================
        output logic                           pcgen_tage_vld,
        output logic [ADDR_WIDTH-1:0]          pcgen_tage_pc
    );


    logic                   pcgen_vld;
    logic [ADDR_WIDTH-1:0]  pc_nxt;
    logic [ADDR_WIDTH-1:0]  pc;

    assign pcgen_vld = ~fe_ctrl_stall;
    assign pc_nxt    = fe_ctrl_chgflw_vld ? fe_ctrl_chgflw_pld.tgt_pc : (pc + (PRED_BLOCK_LEN*4));

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                           pc <= 32'h8000_0000;
        else if(fe_ctrl_chgflw_vld)           pc <= pc_nxt;
    end

    assign fe_ctrl_chgflw_rdy   = icache_req_rdy;
    assign rob_prealloc_req     = pcgen_vld;

    assign icache_req_vld       = pcgen_vld;
    assign icache_req_addr      = {pc[ADDR_WIDTH-1:ALIGN_WIDTH], {ALIGN_WIDTH{1'b0}}} ;
    assign icache_req_entry_id  = rob_prealloc_entry_id;

    assign pcgen_l0btb_vld      = pcgen_vld;
    assign pcgen_l0btb_pc       = pc;

    assign pcgen_btb_vld        = pcgen_vld;
    assign pcgen_btb_pc         = pc;

    assign pcgen_tage_vld       = pcgen_vld;
    assign pcgen_tage_pc        = pc;


endmodule 