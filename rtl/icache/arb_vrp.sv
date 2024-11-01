module arb_vrp #(
    //parameter MODE      = 3, // 0: Fix_Priority 1:Round_Robin 2:Age_Matrix 3: PLRU
    //parameter HSK_MODE  = 1, // 0: Pass 1: 1-Cycle
    parameter WIDTH     = 4,
    parameter PRIORITY  = {WIDTH{1'b1}},
    parameter PLD_WIDTH = 32
)(
    //input                       clk,
    //input                       rst_n,

    input   [WIDTH-1:0]         v_vld_s,
    output  [WIDTH-1:0]         v_rdy_s,
    input   [PLD_WIDTH-1:0]     v_pld_s   [WIDTH-1:0],
    
    output                      vld_m,
    input                       rdy_m,
    output  [PLD_WIDTH-1:0]     pld_m
);

    logic [WIDTH-1:0]       v_grant;
    logic [WIDTH-1:0]       v_vld;
    logic [WIDTH-1:0]       v_rdy;
    logic [PLD_WIDTH-1:0]   m_pld;
    logic                   m_vld;

    assign v_vld = v_vld_s;
    assign v_rdy_s = v_grant & {WIDTH{rdy_m}};
    assign m_vld = |v_vld_s;

    assign vld_m = m_vld;
    assign pld_m = m_pld;



    arb_fp #(
        .WIDTH(WIDTH)
    )  u_arb(
        .v_vld      (v_vld      ),
        .v_priority (PRIORITY   ),
        .v_grant    (v_grant    )
    );

    cmn_real_mux_onehot #(
        .WIDTH          (WIDTH),
        .PLD_WIDTH      (PLD_WIDTH)
    ) u_mux(
        .select_onehot  (v_grant),
        .v_pld          (v_pld_s),
        .select_pld     (m_pld  )
    );

endmodule




