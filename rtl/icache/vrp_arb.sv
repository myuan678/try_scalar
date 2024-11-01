module vrp_arb #(
    parameter integer unsigned WIDTH=8,
    parameter integer unsigned PLD_WIDTH=32
    ) (
    input  logic  [WIDTH-1:0]        v_vld_s,
    input  logic  [PLD_WIDTH-1:0]    v_pld_s[WIDTH-1:0],
    output logic  [WIDTH-1:0]        v_rdy_s,

    input  logic                     rdy_m,
    output logic                     vld_m,
    output logic [PLD_WIDTH-1:0]     pld_m
    );

    logic [WIDTH-1      :0]         select_onehot;
    logic [PLD_WIDTH-1  :0]         select_pld;

    generate
        for(genvar i=0; i<WIDTH; i++) begin : gen_select_onehot
            if(i==0)begin
                assign select_onehot[i] = rdy_m && v_vld_s[i];
            end
            else begin
                //assign select_onehot[i] = select_onehot[i-1] & v_vld_s[i];
                assign select_onehot[i] = rdy_m && v_vld_s[i] && (|v_vld_s[i-1:0]==1'b0);
            end
        end
    endgenerate

    cmn_real_mux_onehot #(
        .WIDTH      (WIDTH          ),
        .PLD_WIDTH  (PLD_WIDTH      )
    ) u_mux (
        .select_onehot(select_onehot),
        .v_pld        (v_pld_s      ),
        .select_pld   (select_pld   )
    );

    assign vld_m = |v_vld_s;
    assign pld_m = select_pld;
    assign v_rdy_s = select_onehot;

endmodule