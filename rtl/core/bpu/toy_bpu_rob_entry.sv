module toy_bpu_rob_entry
    import toy_pack::*;
    (
        input  logic                        clk,
        input  logic                        rst_n,

        input  logic                        icache_prealloc,
        input  logic                        icache_ack_vld,
        input  logic [FETCH_DATA_WIDTH-1:0] icache_ack_pld,

        input  logic                        fe_ctrl_bp2_vld,
        input  logic                        fe_ctrl_bp2_flush,
        input  logic                        fe_ctrl_flush,

        output logic                        rob_entry_wait,
        output logic                        rob_entry_vld,
        output logic                        rob_entry_invalid,

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

    assign filter_pld               = entry_pld;
    assign rob_entry_wait           = entry_wait_0;
    assign rob_entry_vld            = entry_valid;
    assign rob_entry_invalid        = entry_invalid;

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
        else if(fe_ctrl_bp2_vld|icache_ack_vld)     entry_wait_1 <= 1'b1;
        else if(filter_rden|filter_bypass)          entry_wait_1 <= 1'b0;
    end

    // invalid for which entry need release
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_invalid <= 1'b0;
        else if(fe_ctrl_flush)                      entry_invalid <= 1'b0;
        else if(fe_ctrl_bp2_flush)                  entry_invalid <= 1'b1;
        else if(filter_bypass)                      entry_invalid <= 1'b0;
    end

    // valid for entry is ready
    assign entry_enable = (fe_ctrl_bp2_vld&&icache_ack_vld)||(entry_wait_1&&(fe_ctrl_bp2_vld||icache_ack_vld));

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_valid <= 1'b0;
        else if(fe_ctrl_flush)                      entry_valid <= 1'b0;
        else if(filter_rden|filter_bypass)          entry_valid <= 1'b0;
        else if(entry_enable)                       entry_valid <= 1'b1;
    end

    // icache ack pld
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                 entry_pld <= {FETCH_DATA_WIDTH{1'b0}};
        else if(icache_ack_vld)                     entry_pld <= icache_ack_pld;
    end

endmodule 