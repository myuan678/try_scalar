module icache_mshr_file 
    import toy_pack::*;
    (
    input  logic                                        clk                        ,
    input  logic                                        rst_n                      ,    
    input  logic                                        prefetch_enable            ,

    input  logic                                        mshr_update_en             ,
    input  pc_req_t                                     mshr_update_pld            ,
    input  logic                                        pre_tag_req_vld            ,
    input  pc_req_t                                     pre_tag_req_pld            ,
    input  logic rd_vld,

    input  logic  [WAY_NUM-1:0]                         tag_hit                    , //2way
    input  logic                                        tag_way0_hit               ,
    input  logic                                        tag_way1_hit               ,
    input  logic                                        tag_miss                   ,
    input  logic                                        lru_pick                   ,

    output logic                                        alloc_vld                  ,
    output logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           alloc_index                ,
    input  logic                                        alloc_rdy                  ,

    output logic                                        miss_for_prefetch          ,
    input  logic                                        pref_to_mshr_req_rdy       ,
    output req_addr_t                                   miss_addr_for_prefetch     ,
    output logic [ICACHE_REQ_TXNID_WIDTH-1 :0]          miss_txnid_for_prefetch    ,

    output logic                                        dataram_rd_vld             ,
    input  logic                                        dataram_rd_rdy             ,
    output logic                                        dataram_rd_way             ,
    output logic [ICACHE_INDEX_WIDTH-1     :0]          dataram_rd_index           ,
    output logic [ICACHE_REQ_TXNID_WIDTH-1 :0]          dataram_rd_txnid           ,

    output mshr_entry_t                                 v_mshr_entry_array[MSHR_ENTRY_NUM-1:0],
    output logic [MSHR_ENTRY_NUM-1         :0]          v_mshr_entry_array_valid,
    input  logic                                        linefill_done              ,
    input  logic [MSHR_ENTRY_INDEX_WIDTH    :0]         linefill_ack_entry_idx     ,
    output logic [MSHR_ENTRY_INDEX_WIDTH   :0]          entry_release_done_index,
 
    output logic                                        downstream_txreq_vld       ,
    input  logic                                        downstream_txreq_rdy       ,
    output pc_req_t                                     downstream_txreq_pld       ,
    output logic [MSHR_ENTRY_INDEX_WIDTH-1 :0]          downstream_txreq_entry_id  ,

    input  logic                                        downstream_txrsp_vld       ,//TODO
    output logic                                        downstream_txrsp_rdy       ,
    input  logic [ICACHE_REQ_OPCODE_WIDTH-1:0]          downstream_txrsp_opcode    ,//TODO

    output logic [MSHR_ENTRY_NUM-1         :0]          v_hit_entry_done            ,                                
    output logic [MSHR_ENTRY_NUM-1         :0]          v_linefill_done             ,          
    input  logic [MSHR_ENTRY_NUM-1         :0]          bitmap                      ,
    input  dataram_rd_pld_t                             rd_pld                      ,
    input  entry_data_t                                 entry_data                  ,
    output logic                                        mshr_stall                  ,
    input  logic                                        index_way_checkpass                                     
);
    
    logic  [MSHR_ENTRY_NUM-1         :0]                v_entry_en                                      ;
    logic  [MSHR_ENTRY_INDEX_WIDTH-1 :0]                allocate_index                                  ;
    logic                                               allocate_index_vld                              ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_entry_active                                  ;  

    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_vld                                     ; 
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_rdy                                     ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld                                ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy                                ;
    dataram_rd_pld_t                                    v_dataram_rd_pld           [MSHR_ENTRY_NUM-1:0] ;
    dataram_rd_pld_t                                    dataram_rd_pld                                  ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_vld                          ;
    pc_req_t                                            v_downstream_txreq_pld     [MSHR_ENTRY_NUM-1:0] ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_rdy                          ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txrsp_vld                          ;
    logic  [ICACHE_REQ_OPCODE_WIDTH-1:0]                v_downstream_txrsp_opcode  [MSHR_ENTRY_NUM-1:0] ;

    logic  [MSHR_ENTRY_INDEX_WIDTH-1 :0]                dataram_release_index                           ;
    logic                                               dataram_release_index_vld                       ;
    logic  [MSHR_ENTRY_INDEX_WIDTH :0]                downstream_release_index                        ; 
    logic                                               downstream_release_index_vld                    ; 
    
    logic  [MSHR_ENTRY_NUM-1         :0]                v_entry_release_done                            ;
    
    logic                                               arb_dataram_rd_vld                              ;
    logic                                               arb_dataram_rd_rdy                              ;
    dataram_rd_pld_t                                    arb_dataram_rd_pld                              ;

    logic [MSHR_ENTRY_INDEX_WIDTH-1 :0]                 taken_index                                     ;
    logic                                               index_vld                                       ;
    
    logic                                               downstream_txreq_rdy_r                          ;  
    logic [MSHR_ENTRY_NUM-1         :0]                 v_release_en                                    ;


    
   
    assign downstream_txrsp_rdy      = 1'b1                                                             ;
    assign dataram_rd_vld            = rd_vld | arb_dataram_rd_vld                                      ;
    assign dataram_rd_pld            = rd_vld ? rd_pld : arb_dataram_rd_pld                             ;
    assign dataram_rd_way            = dataram_rd_pld.dataram_rd_way                                    ;
    assign dataram_rd_index          = dataram_rd_pld.dataram_rd_index                                  ;
    assign dataram_rd_txnid          = dataram_rd_pld.dataram_rd_txnid                                  ;
    assign mshr_stall                = ( &v_entry_active==1'b1)                                         ;
    //assign alloc_index               = (mshr_update_en && index_vld) ? taken_index : {(MSHR_ENTRY_INDEX_WIDTH+1){1'b1}}                ;
    assign alloc_index               = (mshr_update_en && index_vld) ? taken_index : 'b0               ;
    //assign alloc_index               = (mshr_update_en && alloc_vld) ? taken_index : 'b0               ;
    assign arb_dataram_rd_rdy        = rd_vld ? 1'b0 : dataram_rd_rdy                                   ;
    assign downstream_txreq_entry_id = downstream_release_index[MSHR_ENTRY_INDEX_WIDTH-1 :0]                                         ;

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)    downstream_txreq_rdy_r <= 1'b0;
        else          downstream_txreq_rdy_r <= downstream_txreq_rdy;  
    end
    
    pre_allocate #(
        .ENTRY_NUM      (MSHR_ENTRY_NUM         ),
        .INDEX_WIDTH    (MSHR_ENTRY_INDEX_WIDTH )
    )  u_pre_allocate(
        .clk            (clk                    ),
        .rst_n          (rst_n                  ),
        .cre_tag_req_vld(pre_tag_req_vld        ),
        .rdy_in         (alloc_rdy              ),
        .v_vld_in       (v_alloc_vld            ),
        .taken_vld      (alloc_vld              ),
        .v_rdy_out      (v_alloc_rdy            ),
        .taken_index    (taken_index            ),
        .index_vld      (index_vld              )
    );
    

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM         )
    )   u_entry_en_dec (
        .enable         (mshr_update_en         ),
        //.enable_index   (alloc_index[MSHR_ENTRY_NUM-1:0]            ),
        .enable_index   (alloc_index            ),
        .v_out_en       (v_entry_en             ));

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM         )
    )   u_linefill_done_dec (
        .enable         (linefill_done          ),
        .enable_index   (linefill_ack_entry_idx ),
        .v_out_en       (v_linefill_done        ));


    ////entry_release_done  index
    //cmn_onehot2bin2  #(
    //        .ONEHOT_WIDTH   (MSHR_ENTRY_NUM             )
    //) u_release_done_index(
    //        .onehot_in      (v_entry_release_done       ),
    //        .bin_out        (entry_release_done_index   )
    //    );
    cmn_onehot2bin2  #(
            .ONEHOT_WIDTH   (MSHR_ENTRY_NUM             )
    ) u_release_done_index(
            .onehot_in      (v_release_en       ),
            .bin_out        (entry_release_done_index   )
        );
    
    cmn_onehot2bin2   #(
            .ONEHOT_WIDTH    (MSHR_ENTRY_NUM            )
    ) u_downstream_req_entry_index(
            .onehot_in      (v_downstream_txreq_rdy     ),
            .bin_out        (downstream_release_index   )
        );


    generate
        for (genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:MSHR_ENTRY_ARRAY
            icache_mshr_entry  u_icache_mshr_entry(
                .clk                     (clk                            ),
                .rst_n                   (rst_n                          ),
                .pre_tag_req_vld         (pre_tag_req_vld               ),
                .mshr_entry_array        (v_mshr_entry_array[i]          ),
                .mshr_entry_array_valid  (v_mshr_entry_array_valid[i]    ),
                .v_release_en            (v_release_en                   ),
                .release_en              (v_release_en[i]                ),
                .rd_vld                  (rd_vld                         ), 
                .tag_hit                 (tag_hit                        ),
                .tag_miss                (tag_miss                       ),
                .entry_en                (v_entry_en[i]                  ),
                .entry_data              (entry_data                     ),
                .bitmap                  (bitmap                         ),
                .index_way_checkpass     (index_way_checkpass            ),
                .entry_active            (v_entry_active[i]              ),
                .alloc_vld               (v_alloc_vld[i]                 ),
                .alloc_rdy               (v_alloc_rdy[i]                 ),
                .entry_release_done      (v_entry_release_done[i]        ),
                .dataram_rd_vld          (v_dataram_rd_vld[i]            ),
                .dataram_rd_rdy          (v_dataram_rd_rdy[i]            ),
                .dataram_rd_pld          (v_dataram_rd_pld[i]            ),
                .linefill_done           (v_linefill_done[i]             ),
                .hit_entry_done          (v_hit_entry_done[i]            ),
                .downstream_txreq_vld    (v_downstream_txreq_vld[i]      ),
                .downstream_txreq_rdy    (v_downstream_txreq_rdy[i]      ),
                .downstream_txreq_pld    (v_downstream_txreq_pld[i]      )         
            );
        end
    endgenerate

    //arb_vrp #(
    //    .WIDTH          (MSHR_ENTRY_NUM         ),
    //    .PRIORITY       ({MSHR_ENTRY_NUM{1'b1}} ),
    //    .PLD_WIDTH      ($bits(dataram_rd_pld_t))
    //) u_dataram_rd_arb (
    //    .v_vld_s(v_dataram_rd_vld   ),
    //    .v_rdy_s(v_dataram_rd_rdy   ),
    //    .v_pld_s(v_dataram_rd_pld   ),
    //    .vld_m  (arb_dataram_rd_vld ),
    //    .rdy_m  (arb_dataram_rd_rdy ),
    //    .pld_m  (arb_dataram_rd_pld )
    //);
    vrp_arb #(
        .WIDTH          (MSHR_ENTRY_NUM         ),
        //.PRIORITY       ({MSHR_ENTRY_NUM{1'b1}} ),
        .PLD_WIDTH      ($bits(dataram_rd_pld_t))
    ) u_dataram_rd_arb (
        .v_vld_s(v_dataram_rd_vld   ),
        .v_rdy_s(v_dataram_rd_rdy   ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (arb_dataram_rd_vld ),
        .rdy_m  (arb_dataram_rd_rdy ),
        .pld_m  (arb_dataram_rd_pld )
    );

    arb_vrp #(
        .WIDTH          (MSHR_ENTRY_NUM ),
        .PRIORITY       ({MSHR_ENTRY_NUM{1'b1}}),
        .PLD_WIDTH      ($bits(pc_req_t))
    ) u_downstream_rd_arb (
        .v_vld_s(v_downstream_txreq_vld),
        .v_rdy_s(v_downstream_txreq_rdy),
        .v_pld_s(v_downstream_txreq_pld),
        .vld_m  (downstream_txreq_vld  ),
        .rdy_m  (downstream_txreq_rdy  ),
        .pld_m  (downstream_txreq_pld  )
    );

    always_comb begin
        if(downstream_release_index_vld )begin
            if(prefetch_enable == 1'b1 && pref_to_mshr_req_rdy && downstream_txreq_pld.opcode == UPSTREAM_OPCODE )begin
                miss_for_prefetch       = 1'b1;
                miss_addr_for_prefetch  = v_downstream_txreq_pld[downstream_release_index].addr;
                miss_txnid_for_prefetch = v_downstream_txreq_pld[downstream_release_index].txnid;
            end
            else begin
                miss_for_prefetch       = 1'b0;
                miss_addr_for_prefetch  = '{default: '0} ;
                miss_txnid_for_prefetch = 'b0;
            end
        end
        else begin
            miss_for_prefetch           = 'b0;
            miss_addr_for_prefetch      = 'b0;
            miss_txnid_for_prefetch     = 'b0;
        end
    end


endmodule