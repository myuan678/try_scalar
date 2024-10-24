
module toy_fetch_branch_filter
    import toy_pack::*;
#(
    parameter   int unsigned BRANCH_WIDTH           = 3    ,
    parameter   int unsigned CREDIT_DEPTH           = 128  ,
    localparam  int unsigned ENTRY_WIDTH            = $clog2(CREDIT_DEPTH)     
)
(
    input  logic                            clk                     ,
    input  logic                            rst_n                   ,

    // memory ack
    input  logic                            mem_ack_vld             ,
    input  logic [DATA_WIDTH-1       :0]    mem_ack_data            ,
    input  logic [BRANCH_WIDTH-1     :0]    mem_ack_branch_id       ,
    input  logic [ENTRY_WIDTH-1      :0]    mem_ack_entry_id        ,
    // alu back
    input  logic                            cancel_edge_en          ,
    // input  logic                            pc_update_en            ,
    // input  logic                            pc_release_en           ,
    // req sideband
    output logic [BRANCH_WIDTH-1     :0]    req_branch_id_nxt       ,
    // to inst Q
    output logic                            branch_ack_vld          ,
    output logic [DATA_WIDTH-1       :0]    branch_ack_data         ,
    output logic [ENTRY_WIDTH-1      :0]    branch_ack_entry_id     
);

    //##############################################
    // logic  
    //##############################################
    logic [BRANCH_WIDTH-1       :0]     req_branch_id   ;
    //##############################################
    // Branch filter 
    //##############################################

    assign req_branch_id_nxt = cancel_edge_en ? req_branch_id + 1'b1 : req_branch_id;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            req_branch_id <= {BRANCH_WIDTH{1'b0}};
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


    assign branch_ack_data      = mem_ack_data;
    assign branch_ack_entry_id  = mem_ack_entry_id;



endmodule
