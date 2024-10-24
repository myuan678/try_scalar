
module toy_fetch_pc
    import toy_pack::*;
#(
    localparam  int unsigned INST_NUM_WIDTH   = $clog2(2*FETCH_WRITE_CHANNEL)+1
)(
    input  logic                            clk                     ,
    input  logic                            rst_n                   ,

    // memory access

    output logic [ADDR_WIDTH-1      :0]     mem_req_addr            ,
    output logic                            mem_req_vld             ,
    input  logic                            mem_req_rdy             ,

    // credit vld
    input  logic                            fetch_nxt_vld           ,
    output logic [ADDR_WIDTH-1      :0]     fetch_nxt_pc            ,   
    output logic [INST_NUM_WIDTH-1  :0]     fetch_nxt_num           , 
    output logic                            fetch_nxt_rdy           ,
    
    // pc update
    input  logic                            trap_pc_release_en      ,
    input  logic                            trap_pc_update_en       ,
    input  logic [ADDR_WIDTH-1       :0]    trap_pc_val             ,

    // input  logic                            jb_pc_release_en        ,
    // input  logic                            jb_pc_update_en         ,
    // input  logic [ADDR_WIDTH-1       :0]    jb_pc_val               ,
    input  logic                            cancel_edge_en          ,
    input  logic [ADDR_WIDTH-1       :0]    fetch_update_pc         

    // output logic                            pc_update_en            
    // output logic                            pc_release_en                       
);

    //##############################################
    // parameter
    //##############################################
    localparam  int unsigned FETCH_WR_WIDTH         = $clog2(FETCH_WRITE_CHANNEL)   ;
    localparam  int unsigned ADDR_STEP              = 4*FETCH_WRITE_CHANNEL         ;
    localparam  int unsigned CREDIT_ADD_FILL        = 2*FETCH_WRITE_CHANNEL             ;    
    //##############################################
    // logic  
    //##############################################
    logic                               prediction_vld  ;
    logic                               pc_update_en    ;
    logic [INST_WIDTH-1         :0]     fetch_pc        ;
    logic [ADDR_WIDTH-1         :0]     pc_val          ;
    //##############################################
    // logic 
    //##############################################

    // trap and jb pc update will not valid at the same cycle.
    // assign pc_release_en        = trap_pc_release_en    | jb_pc_release_en      ;
    assign pc_update_en         = trap_pc_update_en     | cancel_edge_en       ;
    assign pc_val               = trap_pc_update_en ? trap_pc_val : fetch_update_pc   ;
    // to mem vld
    assign mem_req_vld          = fetch_nxt_vld                                 ;
    // Fetch PC =========================================================================

    assign prediction_vld   = 1'b1;
    assign fetch_nxt_rdy    = prediction_vld && mem_req_rdy;
    assign mem_req_addr     = fetch_nxt_pc  ;      
    assign fetch_nxt_num    = CREDIT_ADD_FILL - fetch_nxt_pc[FETCH_WR_WIDTH+1 : 1];
    
    always_comb begin
        if(cancel_edge_en)                      fetch_nxt_pc = pc_val;
        else                                    fetch_nxt_pc = fetch_pc;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                      fetch_pc <= 32'h8000_0000       ;
        else if(cancel_edge_en && mem_req_rdy)          fetch_pc <= {pc_val[ADDR_WIDTH-1 : FETCH_WR_WIDTH+2],{(FETCH_WR_WIDTH+2){1'b0}}} + ADDR_STEP          ;
        else if(mem_req_vld && mem_req_rdy)             fetch_pc <= {fetch_pc[ADDR_WIDTH-1 : FETCH_WR_WIDTH+2],{(FETCH_WR_WIDTH+2){1'b0}}} + ADDR_STEP        ;           
        else if(pc_update_en)                           fetch_pc <= fetch_nxt_pc;
    end



endmodule
