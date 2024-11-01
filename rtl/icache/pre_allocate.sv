module pre_allocate 
    import toy_pack::*;
    #(
    parameter ENTRY_NUM = 8, 
    parameter INDEX_WIDTH = $clog2(ENTRY_NUM) 
)(
    input  logic                        clk                 ,
    input  logic                        rst_n               ,
    input  logic                        cre_tag_req_vld     ,
    input  logic  [ENTRY_NUM-1  :0]     v_vld_in            , 
    input  logic                        rdy_in              ,   
    output logic  [ENTRY_NUM-1  :0]     v_rdy_out           , 
    output logic  [INDEX_WIDTH-1:0]     taken_index         , 
    output logic                        index_vld           ,
    output logic                        taken_vld    
);
    logic [ENTRY_NUM-1  :0] selected_chn                    ;
    logic [ENTRY_NUM-1  :0] v_vld_reg                       ;
    logic  [INDEX_WIDTH-1:0]     taken_index_pre;
    logic index_vld_pre;
    //always_ff@(posedge clk or negedge rst_n)begin
    //    if(!rst_n)begin
    //        v_vld_reg <= 'b0;
    //    end
    //    else if(cre_tag_req_vld)begin
    //        v_vld_reg <= v_vld_in;
    //    end
    //    else begin
    //        v_vld_reg <= 'b0;
    //    end
    //end
    //cmn_lead_one #(
    //    .ENTRY_NUM      (MSHR_ENTRY_NUM   )
    //) u_allocate_one(
    //    .v_entry_vld    (v_vld_reg        ),
    //    .v_free_idx_oh  (selected_chn     ),
    //    .v_free_idx_bin (taken_index      ),
    //    .v_free_vld     (index_vld        )
    //);
    cmn_lead_one #(
        .ENTRY_NUM      (MSHR_ENTRY_NUM   )
    ) u_allocate_one(
        .v_entry_vld    (v_vld_in        ),
        .v_free_idx_oh  (selected_chn     ),
        .v_free_idx_bin (taken_index_pre      ),
        .v_free_vld     (index_vld_pre        )
    );

    always_ff@(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            taken_index <= 'b0;
            index_vld <= 1'b0;
        end
        else begin
            taken_index <= taken_index_pre;
            index_vld <= index_vld_pre;
        end
    end

    assign v_rdy_out = selected_chn;
    assign taken_vld = |v_vld_in;
endmodule


    






//module pre_allocate
//    import toy_pack::*;
//    #(parameter INDEX_WIDTH = $clog2(MSHR_ENTRY_NUM) 
//    )
//    (
//    input  logic                          clk               ,
//    input  logic                          rst_n             ,
//    input  logic [MSHR_ENTRY_NUM-1:0]     v_in_vld          ,
//    output logic [MSHR_ENTRY_NUM-1:0]     v_in_rdy          ,
//    output logic                          out_vld           ,
//    input  logic                          out_rdy           ,
//    output logic  [INDEX_WIDTH-1:0]       out_index
//    );
////------
////---signals
////------
//logic [INDEX_WIDTH-1:0]  free_mshr_id                          ;
//logic [MSHR_ENTRY_NUM-1:0] free_mshr_oh                          ;
//logic                          free_mshr_vld                         ;
//
//logic mshr_id_wr         ;
//logic mshr_id_rd         ;
//logic pre_allo_buf_empty ;
//logic pre_allo_buf_full  ;
//
//cmn_lead_one #(
//    .ENTRY_NUM (MSHR_ENTRY_NUM)
//) u_cmn_lead_one(
//    .v_entry_vld    (v_in_vld           ),
//    .v_free_idx_oh  (free_mshr_oh       ),
//    .v_free_idx_bin (free_mshr_id       ),
//    .v_free_vld     (free_mshr_vld      )
//);
//assign v_in_rdy   = (free_mshr_vld && !pre_allo_buf_full) ? free_mshr_oh : {INDEX_WIDTH{1'b0}};
//
//assign mshr_id_wr = free_mshr_vld      ;
//assign mshr_id_rd = out_vld && out_rdy ;
//
//fifo#(
//    .DATA_WIDTH(INDEX_WIDTH      ),
//    .ADDR_WIDTH(4     )
//)u_fifo(
//    .clk   (clk                  ),
//    .rst_n (rst_n                ),
//    .wr_ena(mshr_id_wr           ),
//    .rd_ena(mshr_id_rd           ),
//    .din   (free_mshr_id         ),
//    .dout  (out_index            ),
//    .full  (pre_allo_buf_full    ),
//    .empty (pre_allo_buf_empty   )
//);
//assign  out_vld = !pre_allo_buf_empty;
//
//endmodule