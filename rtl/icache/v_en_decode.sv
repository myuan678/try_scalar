module v_en_decode #(
    parameter integer unsigned WIDTH=8
    )(
    input  logic                      enable      ,
    input  logic [$clog2(WIDTH)-1:0]  enable_index,
    output logic [WIDTH-1:0]          v_out_en
    );

    generate
        for (genvar i = 0; i < WIDTH; i=i+1) begin : gen_v_out_en
            always_comb begin
                v_out_en[i] = 'b0;
                if(i==enable_index  &&  enable)begin
                    v_out_en[i] = 1'b1;
                end
            end
        end
    endgenerate

endmodule
