module icache_tag_array_ctrl
    import toy_pack::*;
    (
    input  logic                                        clk                     ,
    input  logic                                        rst_n                   ,
    input  logic                                        dataram_rd_rdy          ,
    input  logic                                        tag_req_vld             ,
    output logic                                        tag_req_rdy             ,
    input  pc_req_t                                     tag_req_pld             ,
    input  logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           tag_req_index           ,
    output logic                                        tag_miss                ,
    output logic [WAY_NUM-1:0]                          tag_hit                 ,


    output logic                                        tag_way0_hit            ,   
    output logic                                        tag_way1_hit            ,
    output logic                                        lru_pick                ,
    output logic                                        mshr_update_en          ,
    output pc_req_t                                     mshr_update_pld         ,

    output logic                                        pre_tag_req_vld         ,
    output pc_req_t                                     pre_tag_req_pld         ,

    //output logic                                        req_vld                 ,
    output logic                                        cre_tag_req_vld,

    input  logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           entry_release_done_index,
    input  logic [MSHR_ENTRY_NUM-1        :0]           v_linefill_done         ,
    input  logic [MSHR_ENTRY_NUM-1        :0]           v_hit_entry_done        ,
    input  mshr_entry_t                                 v_mshr_entry_array[MSHR_ENTRY_NUM-1:0],
    input  logic [MSHR_ENTRY_NUM-1        :0]           v_mshr_entry_array_valid,

    input logic                                         stall                   ,
    output dataram_rd_pld_t                             rd_pld                  ,
    output logic                                        rd_vld                  ,
    output entry_data_t                                 entry_data              ,
    output logic                                        index_way_checkpass     ,
    output logic [MSHR_ENTRY_NUM-1        :0]           bitmap

    );

    logic [MSHR_ENTRY_NUM-1        :0]   v_index_way_bitmap[MSHR_ENTRY_NUM-1:0] ;
    logic                                tag_array0_wr_en                       ;
    logic [ICACHE_INDEX_WIDTH-1    :0]   tag_array0_addr                        ;
    logic [ICACHE_TAG_RAM_WIDTH-1  :0]   tag_array0_dout                        ;
    logic                                tag_array0_dout_way0_vld               ;
    logic                                tag_array0_dout_way1_vld               ;
    logic [ICACHE_TAG_RAM_WIDTH-1  :0]   tag_array0_din                         ;
    logic [2**ICACHE_INDEX_WIDTH-1 :0]   lru                                    ;
    logic                                mem_en                                 ;
    logic [ICACHE_INDEX_WIDTH-1    :0]   index                                  ;
    logic [ICACHE_TAG_RAM_WIDTH-1  :0]   wr_tag_buf_pld                         ;
    logic                                wr_tag_buf_vld                         ;
    logic                                wr_tag_buf_rdy                         ;
    logic [ICACHE_TAG_RAM_WIDTH/2-1:0]   dout_buf                               ;
    pc_req_t                             cre_tag_req_pld                        ;
    logic [MSHR_ENTRY_NUM-1        :0]   v_index_way_bit_keep[MSHR_ENTRY_NUM-1:0];
    logic [ICACHE_INDEX_WIDTH-1    :0]   wr_tag_buf_index                       ;
    logic                                lru_pick_tmp                           ;
    logic                                pre_check_pass                         ;
    logic [MSHR_ENTRY_NUM-1        :0]   bitmap_keep                            ;
    pc_req_t                                     req_pld;
    logic                                        req_vld;

    

    assign entry_data.pld            = mshr_update_pld                                              ;
    assign entry_data.dest_way       = lru_pick_tmp                                                 ;
    assign tag_array0_addr           = wr_tag_buf_vld ? wr_tag_buf_index : tag_req_pld.addr.index   ;
    assign tag_array0_wr_en          = wr_tag_buf_vld                                               ;
    assign tag_array0_din            = wr_tag_buf_pld                                               ;
    assign cre_tag_req_vld           = tag_req_vld && tag_req_rdy  &&   wr_tag_buf_vld==1'b0        ;
    assign index                     = req_pld.addr.index                                           ;
    assign mem_en                    = wr_tag_buf_vld | pre_tag_req_vld                                 ;
    assign tag_req_rdy               = (wr_tag_buf_vld==1'b0) && (stall==1'b0)                      ;
    assign tag_hit                   = {tag_way0_hit,tag_way1_hit}                                  ;
    assign tag_miss                  = ~(tag_way0_hit | tag_way1_hit) && req_vld                    ;
    //assign tag_miss                  = ~(tag_way0_hit | tag_way1_hit)                     ;
    assign tag_array0_dout_way0_vld  = tag_array0_dout[ICACHE_TAG_RAM_WIDTH-1]                      ;
    assign tag_array0_dout_way1_vld  = tag_array0_dout[ICACHE_TAG_RAM_WIDTH/2-1]                    ;
    assign pre_check_pass            = ((|bitmap)==1'b0)                                            ;
    assign rd_vld                    = |tag_hit & pre_check_pass && dataram_rd_rdy                  ;
    assign rd_pld.dataram_rd_index   = mshr_update_pld.addr.index                                   ;
    assign rd_pld.dataram_rd_way     = tag_way0_hit ? 1'b0 : 1'b1                                   ;
    assign rd_pld.dataram_rd_txnid   = mshr_update_pld.txnid                                        ;
    assign pre_tag_req_pld           = tag_req_pld                                                  ;

    always_comb begin
        if(wr_tag_buf_vld==1'b0)   pre_tag_req_vld = cre_tag_req_vld;
        else                       pre_tag_req_vld = 1'b0       ;
    end
    //always_comb begin
    //    tag_array0_dout_way0_vld = 1'b0;
    //    tag_array0_dout_way1_vld = 1'b0;
    //    if(wr_tag_buf_vld)begin
    //        tag_array0_dout_way0_vld  = tag_array0_dout[ICACHE_TAG_RAM_WIDTH-1]  ;
    //        tag_array0_dout_way1_vld  = tag_array0_dout[ICACHE_TAG_RAM_WIDTH/2-1];
    //    end
    //end


    ///////req_pld buffer
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)      req_vld <= 1'b0         ;
        else            req_vld <= cre_tag_req_vld  ;
    end
    always_ff@(posedge clk)begin
        if(~wr_tag_buf_vld)begin
            req_pld     <= tag_req_pld;
        end
    end

    toy_mem_model_bit #(
        .ADDR_WIDTH(ICACHE_INDEX_WIDTH   ),
        .DATA_WIDTH(ICACHE_TAG_RAM_WIDTH )
    ) u_icache_tag_array0(
        .clk        (clk                 ),
        .en         (mem_en              ),
        .wr_en      (tag_array0_wr_en    ),
        .addr       (tag_array0_addr     ),
        .rd_data    (tag_array0_dout     ),
        .wr_data    (tag_array0_din      )
    );

//----------------------------------------------//
//             update wr buffer
//----------------------------------------------//
//wr_en  1:write; 0:read
//if snp miss, nothing to do; if hit,update tag.valid and lru
//if  read miss,update tag array; if hit,update lru
    always_ff@(posedge clk)begin
        if(tag_miss)begin
            wr_tag_buf_pld      <= lru_pick ? {tag_array0_dout[ICACHE_TAG_RAM_WIDTH-1:ICACHE_TAG_RAM_WIDTH/2],1'b1,req_pld.addr.tag}
                                        : {1'b1,req_pld.addr.tag, tag_array0_dout[ICACHE_TAG_RAM_WIDTH/2-1:0]};
            wr_tag_buf_index    <= req_pld.addr.index;
        end
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)              wr_tag_buf_vld <= 1'b0;
        else if(tag_miss)       wr_tag_buf_vld <= (req_pld.opcode== UPSTREAM_OPCODE) || (req_pld.opcode== PREFETCH_OPCODE);
        else if(wr_tag_buf_vld) wr_tag_buf_vld <= 1'b0;
        else                    wr_tag_buf_vld <= 1'b0;
    end


    always_comb begin
        tag_way0_hit = 1'b0;
        tag_way1_hit = 1'b0;
        if(req_vld)begin
            if(wr_tag_buf_vld && (req_pld.addr.index==wr_tag_buf_index))begin
                if(({1'b1,req_pld.addr.tag}==wr_tag_buf_pld[ICACHE_TAG_RAM_WIDTH-1:ICACHE_TAG_RAM_WIDTH/2]))begin
                    tag_way0_hit = 1'b1;
                    tag_way1_hit = 1'b0;
                end
                else if(({1'b1,req_pld.addr.tag}==wr_tag_buf_pld[ICACHE_TAG_RAM_WIDTH/2-1:0]))begin
                    tag_way0_hit = 1'b0;
                    tag_way1_hit = 1'b1;
                end
            end
            else begin
                if(({1'b1,req_pld.addr.tag}==tag_array0_dout[ICACHE_TAG_RAM_WIDTH-1:ICACHE_TAG_RAM_WIDTH/2]))begin
                    tag_way0_hit = 1'b1;
                    tag_way1_hit = 1'b0;
                end
                else if(({1'b1,req_pld.addr.tag}==tag_array0_dout[ICACHE_TAG_RAM_WIDTH/2-1:0]))begin
                    tag_way0_hit = 1'b0;
                    tag_way1_hit = 1'b1;
                end
            end
        end

    end

//----------------------------------//
//        behavior map
//----------------------------------//
    assign mshr_update_pld = req_pld;
    always_comb begin
        mshr_update_en = 1'b0;
        if(req_vld)begin
            if(req_pld.opcode== DOWNSTREAM_OPCODE) mshr_update_en = 1'b0;
            else                                   mshr_update_en = 1'b1;
        end
    end

    
    generate 
        for (genvar i = 0; i < MSHR_ENTRY_NUM; i++)begin
            always_comb begin
                bitmap[i] = 0;
                if(mshr_update_en)begin
                    if((i==tag_req_index) | (i==entry_release_done_index))begin
                       bitmap[i] = 1'b0; 
                    end
                    //else if(v_mshr_entry_array[i].valid && (v_mshr_entry_array[i].req_pld.addr.index==req_pld.addr.index) && ((v_mshr_entry_array[i].dest_way==(~tag_way0_hit)) | (v_mshr_entry_array[i].dest_way==(tag_way1_hit))))begin
                    //else if(v_mshr_entry_array[i].valid && (v_mshr_entry_array[i].req_pld.addr.index==req_pld.addr.index) && (v_mshr_entry_array[i].dest_way==lru_pick_tmp))begin
                    else if(v_mshr_entry_array_valid[i] && (v_mshr_entry_array[i].req_pld.addr.index==req_pld.addr.index) && ((v_mshr_entry_array[i].dest_way==(~tag_way0_hit)) | (v_mshr_entry_array[i].dest_way==(tag_way1_hit))))begin
                        bitmap[i] = 1'b1; 
                    end
                end
            end
        end
    endgenerate
    assign index_way_checkpass = (|bitmap==1'b0);


//----------------------------------//
//        lru update
//----------------------------------//
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            lru             <= 'b0                      ;
        end
        else if (tag_array0_dout_way0_vld == 1'b0)begin
            lru[index]      <= 1'b0                     ;
        end
        else if (tag_array0_dout_way0_vld == 1'b1 && tag_array0_dout_way1_vld == 1'b0)begin
            lru[index]      <= 1'b1                     ;
        end
        else if (tag_array0_dout_way0_vld == 1'b1 && tag_array0_dout_way1_vld == 1'b1)begin
            if ((tag_way0_hit == 1'b1)  && (tag_way1_hit == 1'b0))begin
                lru[index]  <= 1'b1                     ;
            end
            else if ((tag_way0_hit == 1'b0)  && (tag_way1_hit == 1'b1)) begin
                lru[index]  <= 1'b0                     ;
            end
            else if (tag_miss) begin
                lru[index]  <= ~lru[index]              ;
            end
        end
    end
    assign lru_pick = lru[index];

    always_comb begin
        if(tag_way0_hit)        lru_pick_tmp = 1'b0;
        else if(tag_way1_hit)   lru_pick_tmp = 1'b1;
        else                    lru_pick_tmp = lru[index];
    end


endmodule
