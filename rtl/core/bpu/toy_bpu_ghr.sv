module toy_bpu_ghr
    import toy_pack::*;
    (
        input   logic                       clk   ,
        input   logic                       rst_n ,

        // BP1 TAGE ===========================================================
        input   logic                       bpu_pred_vld     ,
        input   logic                       bpu_pred_taken   ,
        output  logic [GHR_LENGTH-1:0]      bpu_ghr          ,

        // FE Controller ======================================================
        input   logic                       fe_ctrl_be_chgflw_vld      ,
        input   logic                       fe_ctrl_be_chgflw_taken,
        input   logic                       fe_ctrl_be_flush,
        input   logic                       fe_ctrl_ras_enqueue_vld,
        input   logic                       fe_ctrl_ras_enqueue_taken,
        input   logic                       fe_ctrl_ras_flush

    );

    logic [GHR_LENGTH-1:0]  ghr;
    logic [GHR_LENGTH-1:0]  eq_ghr;
    logic [GHR_LENGTH-1:0]  rtu_ghr;

    
    assign bpu_ghr = ghr;

    // backup enqueue ghr
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                              eq_ghr  <= {GHR_LENGTH{1'b0}};
        else if(fe_ctrl_be_flush)               eq_ghr  <= {rtu_ghr[GHR_LENGTH-2:0], fe_ctrl_be_chgflw_taken};
        else if(fe_ctrl_ras_enqueue_vld)        eq_ghr  <= {eq_ghr[GHR_LENGTH-2:0] , fe_ctrl_ras_enqueue_taken};
    end

    // backup commit ghr
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                              rtu_ghr <= {GHR_LENGTH{1'b0}};
        else if(fe_ctrl_be_chgflw_vld)          rtu_ghr <= {rtu_ghr[GHR_LENGTH-2:0], fe_ctrl_be_chgflw_taken};
    end

    // ghr
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                              ghr     <= {GHR_LENGTH{1'b0}};
        else if(fe_ctrl_be_flush)               ghr     <= {rtu_ghr[GHR_LENGTH-2:0], fe_ctrl_be_chgflw_taken};
        else if(fe_ctrl_ras_flush)              ghr     <= {eq_ghr[GHR_LENGTH-2:0] , fe_ctrl_ras_enqueue_taken};
        else if(bpu_pred_vld)                   ghr     <= {ghr[GHR_LENGTH-2:0]    , bpu_pred_taken};
    end

//TODO:compress ghr opt

endmodule