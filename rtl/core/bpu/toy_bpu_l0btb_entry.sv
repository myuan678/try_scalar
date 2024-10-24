module toy_bpu_l0btb_entry
    import toy_pack::*;
    (
        input logic                clk,
        input logic                rst_n,

        input logic                entry_update,
        input logic                entry_update_inv,
        input l0btb_entry_pkg      entry_update_pld,

        output logic               entry_vld,
        output l0btb_entry_pkg     entry_pld

    );

    logic                          entry_pred_vld;
    l0btb_entry_pkg                entry_pred_pld;          

    logic                          entry_inv;
    logic                          entry_updt;

    assign entry_vld                = entry_pred_vld;
    assign entry_pld                = entry_pred_pld;

    assign entry_inv                = entry_update && entry_update_inv ;
    assign entry_updt               = entry_update && ~entry_update_inv;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)              entry_pred_vld   <= 1'b0;
        else if(entry_inv)      entry_pred_vld   <= 1'b0;
        else if(entry_updt)     entry_pred_vld   <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)              entry_pred_pld   <= {($bits(l0btb_entry_pkg)){1'b0}};
        else if(entry_updt)     entry_pred_pld   <= entry_update_pld;
    end


endmodule 