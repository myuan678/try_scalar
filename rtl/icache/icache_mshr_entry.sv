module icache_mshr_entry 
    import toy_pack::*; 
    (
    input  logic                                        clk                        ,
    input  logic                                        rst_n                      , 
    input  logic                                        pre_tag_req_vld            ,
    input  logic                                        rd_vld                     ,
    input  logic  [WAY_NUM-1                :0]         tag_hit                    , //2way
    input  logic                                        tag_miss                   ,
    input  logic                                        entry_en                   ,
    input  entry_data_t                                 entry_data                 ,
    input  logic [MSHR_ENTRY_NUM-1          :0]         bitmap                     ,
    input  logic                                        index_way_checkpass        ,

    output logic                                        dataram_rd_vld             ,
    input  logic                                        dataram_rd_rdy             ,
    output dataram_rd_pld_t                             dataram_rd_pld             ,

    output logic                                        entry_active               ,
    output logic                                        alloc_vld                  ,   
    input  logic                                        alloc_rdy                  ,    
    output logic                                        entry_release_done         ,
    output logic                                        downstream_txreq_vld       ,
    input  logic                                        downstream_txreq_rdy       ,
    output pc_req_t                                     downstream_txreq_pld       ,
    output mshr_entry_t                                 mshr_entry_array           ,
    output logic                                        hit_entry_done             ,
    input  logic                                        linefill_done              ,
    output logic                                        mshr_entry_array_valid,

    input  logic [MSHR_ENTRY_NUM-1          :0]         v_release_en               ,
    output logic                                        release_en

    );

    logic                                               dataram_rd_way             ;
    logic [ICACHE_INDEX_WIDTH-1      :0]                dataram_rd_index           ;
    logic [ICACHE_REQ_TXNID_WIDTH-1  :0]                dataram_rd_txnid           ;
    logic                                               linefill_sent ;
    logic                                               linefill_data_done;
    logic                                               state_done;
    //logic                                               state_rd_dataram;
    logic                                               state_rd_dataram_sent;
    //logic                                               rd_dataram_done;
    logic                                               rxreq_type    ;
    logic                                               pref_type     ;
    logic                                               snp_type      ;
    logic                                               allocate_en;
    logic                                               hazard_free;
    logic                                               index_way_release;
    logic [MSHR_ENTRY_NUM-1:0]                          v_hazard_bitmap;
    logic e_state_done;
    logic first_valid;
    
    

    assign allocate_en            = rd_vld ? 1'b0 : entry_en;
    assign rxreq_type             = mshr_entry_array.req_pld.opcode == UPSTREAM_OPCODE;
    assign pref_type              = mshr_entry_array.req_pld.opcode == PREFETCH_OPCODE;
    assign snp_type               = mshr_entry_array.req_pld.opcode == DOWNSTREAM_OPCODE;

    assign alloc_vld              =  ~entry_active                      ;
    assign entry_active           = first_valid | mshr_entry_array_valid;
    //assign entry_active           = mshr_entry_array.valid              ;
    assign dataram_rd_index       = mshr_entry_array.req_pld.addr.index ;
    assign dataram_rd_way         = mshr_entry_array.dest_way           ;
    assign dataram_rd_txnid       = mshr_entry_array.req_pld.txnid      ;
    assign hit_entry_done         = state_rd_dataram_sent               ;
    assign entry_release_done     = state_done                          ;          
    assign index_way_release      = ((|v_hazard_bitmap)==1'b0)          ;


    always_ff@(posedge clk or negedge rst_n) begin
        if (~rst_n)begin
            mshr_entry_array.req_pld   <= 'b0;
            mshr_entry_array.dest_way  <= 'b0;
            mshr_entry_array.hit       <= 'b0;
            mshr_entry_array.miss      <= 'b0;
        end
        else if(allocate_en)begin
            mshr_entry_array.req_pld   <= entry_data.pld      ;
            mshr_entry_array.dest_way  <= entry_data.dest_way ;
            mshr_entry_array.hit       <= |tag_hit            ;
            mshr_entry_array.miss      <= tag_miss            ;
        end
    end
    //always_ff@(posedge clk or negedge rst_n) begin
    //    if(~rst_n)                                              mshr_entry_array.valid <= 1'b0;
    //    else if(allocate_en)                                    mshr_entry_array.valid <= 1'b1;
    //    else if(state_rd_dataram_sent && mshr_entry_array.hit)  mshr_entry_array.valid <= 1'b0;
    //    else if(linefill_data_done && mshr_entry_array.miss)    mshr_entry_array.valid <= 1'b0;   
    //    else                                                    mshr_entry_array.valid <= mshr_entry_array.valid;
    //end
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                              mshr_entry_array_valid <= 1'b0;
        else if(allocate_en)                                    mshr_entry_array_valid <= 1'b1;
        else if(state_rd_dataram_sent && mshr_entry_array.hit)  mshr_entry_array_valid <= 1'b0;
        else if(linefill_data_done && mshr_entry_array.miss)    mshr_entry_array_valid <= 1'b0;   
        else                                                    mshr_entry_array_valid <= mshr_entry_array_valid;
    end
    assign first_valid = allocate_en ? 1'b1 : 1'b0;

    

//========================================================
// hazard_checking WAIT_dependency
//========================================================
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n) hazard_free <= 1'b0;
        else       hazard_free <= (index_way_checkpass && allocate_en ) | (index_way_release && entry_active);
    end
    
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)              v_hazard_bitmap <= 'b0;
        else if(allocate_en)    v_hazard_bitmap <= bitmap;
        else                    v_hazard_bitmap <= v_hazard_bitmap &(~v_release_en);
    end


//========================================================
// read dataram   RD_DATARAM state
//========================================================
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                  state_rd_dataram_sent <= 1'b1;
    else if(allocate_en)                        state_rd_dataram_sent <= ~(|tag_hit);
    else if(dataram_rd_vld && dataram_rd_rdy)   state_rd_dataram_sent <= 1'b1;
end

//========================================================
// req downstream   REQ_LINEFILL state
//========================================================
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                            linefill_sent <= 1'b1;
    else if(allocate_en)                                  linefill_sent <= ~tag_miss;
    else if(downstream_txreq_vld && downstream_txreq_rdy) linefill_sent <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)              linefill_data_done <= 1'b1;
    else if(allocate_en )   linefill_data_done <= ~tag_miss;
    else if(linefill_done)  linefill_data_done <= 1'b1;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                               state_done <= 1'b0;
    else if(linefill_data_done | (allocate_en && snp_type)  )state_done <= 1'b1;
    else                                                     state_done <= 1'b0;
end
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                               e_state_done <= 1'b0;
    else if(linefill_data_done | (allocate_en && snp_type) | state_rd_dataram_sent ) e_state_done <= 1'b1;
    else                                                     e_state_done <= 1'b0;
end
//assign release_en = linefill_data_done & linefill_sent & state_rd_dataram_sent;
assign release_en = linefill_data_done & state_rd_dataram_sent;

//========================================================
// req downstream   REQ_LINEFILL state
//========================================================

    assign dataram_rd_vld                   = hazard_free && (~state_rd_dataram_sent);
    assign dataram_rd_pld.dataram_rd_way    = dataram_rd_way    ;
    assign dataram_rd_pld.dataram_rd_index  = dataram_rd_index  ;  
    assign dataram_rd_pld.dataram_rd_txnid  = dataram_rd_txnid  ;

    assign downstream_txreq_vld             = hazard_free && (~linefill_sent);
    assign downstream_txreq_pld             = mshr_entry_array.req_pld;




endmodule
