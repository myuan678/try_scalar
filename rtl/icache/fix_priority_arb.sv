module fix_priority_arb #(
    parameter type              PLD_TYPE = logic                 ,
    parameter integer unsigned  WIDTH    = 3           
    ) (
    input  [WIDTH-1         :0]        v_vld_s                   ,    
    output [WIDTH-1         :0]        v_rdy_s                   ,    
    input  PLD_TYPE                    v_pld_s [WIDTH-1:0]       , 
            
    output                             vld_m                     ,      
    input                              rdy_m                     ,      
    output PLD_TYPE                    pld_m       
);

    logic [WIDTH-1          :0]        select_onehot             ;
    logic [$clog2(WIDTH)-1  :0]        selected_bin              ;

    assign vld_m        = |v_vld_s                               ;
    assign pld_m        = v_pld_s[selected_bin]                  ;
    //assign v_rdy_s      = select_onehot                          ;
    assign v_rdy_s      = {WIDTH{rdy_m}} & select_onehot         ;

    generate 
        for(genvar i=0;i<WIDTH;i=i+1)begin:select_req
            if(i==0)begin
                assign select_onehot[i] = rdy_m && v_vld_s[i]    ;
            end
            else begin
                assign select_onehot[i] = rdy_m && (v_vld_s[i] && (|v_vld_s[i-1:0]== 1'b0) )  ;
            end
        end
    endgenerate

    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WIDTH         )
    )u_oh2bin(
        .onehot_in(select_onehot    ),
        .bin_out  (selected_bin     )
    );

endmodule