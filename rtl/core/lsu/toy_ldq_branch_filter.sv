
module toy_ldq_branch_filter
    import toy_pack::*;
#(
    parameter   int unsigned BRANCH_WIDTH           = 3       
)
(
    input  logic                            clk                     ,
    input  logic                            rst_n                   ,

    // memory ack
    input  logic                            mem_ack_vld             ,
    input  logic [BRANCH_WIDTH-1     :0]    mem_ack_branch_id       ,
    // alu back
    input  logic                            cancel_edge_en          ,
    // req sideband
    output logic [BRANCH_WIDTH-1     :0]    req_branch_id_nxt       ,
    // to inst Q
    output logic                            branch_ack_vld          
);

    //##############################################
    // logic  
    //##############################################
    logic [BRANCH_WIDTH-1       :0]     req_branch_id   ;
    //##############################################
    // Branch filter 
    //##############################################

    // assign req_branch_id_nxt = (cancel_edge_en) ? (req_branch_id=={BRANCH_WIDTH{1'b0}})? 1 : req_branch_id + 1'b1 : req_branch_id;

    always_comb begin
        if (cancel_edge_en) begin
            if((req_branch_id=={BRANCH_WIDTH{1'b1}})) begin
                req_branch_id_nxt = BRANCH_WIDTH'(1);
            end
            else begin
                req_branch_id_nxt = req_branch_id + 1'b1;
            end
        end
        else begin
            req_branch_id_nxt = req_branch_id;
        end
        
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            req_branch_id <= BRANCH_WIDTH'(1);
        end
        else if(cancel_edge_en)begin
            req_branch_id <= req_branch_id_nxt;
        end
    end


    always_comb begin
        if(mem_ack_branch_id == req_branch_id)begin
            branch_ack_vld = mem_ack_vld;
        end
        else if(cancel_edge_en && (mem_ack_branch_id == req_branch_id_nxt))begin
            branch_ack_vld = mem_ack_vld;
        end
        else begin
            branch_ack_vld = 1'b0;
        end
    end

endmodule
