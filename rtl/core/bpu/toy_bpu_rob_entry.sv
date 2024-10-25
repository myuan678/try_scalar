module toy_bpu_rob_entry
    import toy_pack::*;
    (
        input  logic                        clk,
        input  logic                        rst_n,

        input  logic                        icache_prealloc,
        input  logic                        icache_ack_vld,
        input  logic [FETCH_DATA_WIDTH-1:0] icache_ack_pld,

        input  logic                        bpdec_bp2_vld,
        input  logic                        bpdec_bp2_flush,
        input  logic                        fe_ctrl_flush,

        output logic                        rob_entry_wait_0,
        output logic                        rob_entry_valid,
        output logic                        rob_entry_invalid,
        output logic                        rob_entry_nxt_valid,
        output logic                        rob_entry_nxt_invalid,
        output logic [FETCH_DATA_WIDTH-1:0] rob_entry_nxt_pld,

        input  logic                        filter_rden,
        input  logic                        filter_bypass,
        output logic [FETCH_DATA_WIDTH-1:0] filter_pld
    );

    logic                           entry_wait_0; // prealloc and wait icache response
    logic                           entry_wait_1; // wait 
    logic                           entry_invalid;
    logic                           entry_valid;
    logic [FETCH_DATA_WIDTH-1:0]    entry_pld;

    logic                           entry_enable;
    logic                           entry_nxt_valid;
    logic                           entry_nxt_invalid;
    logic [FETCH_DATA_WIDTH-1:0]    entry_nxt_pld;
    logic                           entry_valid_enable;
    logic                           entry_invalid_enable;

    assign filter_pld               = entry_pld;
    assign rob_entry_wait_0         = entry_wait_0;
    assign rob_entry_valid          = entry_valid;
    assign rob_entry_invalid        = entry_invalid;
    assign rob_entry_nxt_valid      = entry_nxt_valid;
    assign rob_entry_nxt_invalid    = entry_nxt_invalid;
    assign rob_entry_nxt_pld        = entry_nxt_pld;


    // wait 0 for after prealloc and wait bp2 or icache ack
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_wait_0 <= 1'b0;
        else if(icache_prealloc)                    entry_wait_0 <= 1'b1;
        else if(icache_ack_vld)                     entry_wait_0 <= 1'b0;
    end

    // wait 1 for one arrive
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_wait_1 <= 1'b0;
        else if(fe_ctrl_flush)                      entry_wait_1 <= 1'b0;
        else if(bpdec_bp2_vld|icache_ack_vld)       entry_wait_1 <= 1'b1;
        else if(filter_rden|filter_bypass)          entry_wait_1 <= 1'b0;
    end

    // invalid for which entry need release
    assign entry_invalid_enable     = fe_ctrl_flush||bpdec_bp2_flush||filter_bypass;

    always_comb begin
        if(fe_ctrl_flush)                           entry_nxt_invalid = 1'b0;
        else if(bpdec_bp2_flush)                    entry_nxt_invalid = 1'b1;
        else if(filter_bypass)                      entry_nxt_invalid = 1'b0;
        else                                        entry_nxt_invalid = entry_invalid;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_invalid <= 1'b0;
        else if(entry_invalid_enable)               entry_invalid <= entry_nxt_invalid;
    end

    // valid for entry is ready
    assign entry_enable         = (bpdec_bp2_vld&&icache_ack_vld)||(entry_wait_1&&(bpdec_bp2_vld||icache_ack_vld));
    assign entry_valid_enable   = entry_enable||filter_rden||filter_bypass||fe_ctrl_flush;

    always_comb begin 
        if(fe_ctrl_flush)                           entry_nxt_valid = 1'b0;
        else if(filter_rden|filter_bypass)          entry_nxt_valid = 1'b0;
        else if(entry_enable)                       entry_nxt_valid = 1'b1;
        else                                        entry_nxt_valid = entry_valid;
    end 

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_valid <= 1'b0;
        else if(entry_valid_enable)                 entry_valid <= entry_nxt_valid;
    end

    always_comb begin 
        if(icache_ack_vld)                          entry_nxt_pld = icache_ack_pld;
        else                                        entry_nxt_pld = entry_pld;
    end 

    // icache ack pld
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_pld <= {FETCH_DATA_WIDTH{1'b0}};
        else if(icache_ack_vld)                     entry_pld <= entry_nxt_pld;
    end

endmodule 