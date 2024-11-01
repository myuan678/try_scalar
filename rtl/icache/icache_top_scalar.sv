module icache_top
    import toy_pack::*;
    (
    input  logic                                        clk                         ,
    input  logic                                        rst_n                       ,
    input  logic                                        prefetch_enable             ,
    //upstream txdat  out
    output logic [ICACHE_UPSTREAM_DATA_WIDTH-1 :0]      upstream_txdat_data         ,
    output logic                                        upstream_txdat_vld          ,
    output logic [ICACHE_REQ_TXNID_WIDTH-1     :0]      upstream_txdat_txnid        ,
    input  logic                                        upstream_txdat_rdy          ,
    

    //upstream rxreq
    input  logic                                        upstream_rxreq_vld          ,
    output logic                                        upstream_rxreq_rdy          ,
    /////////try to match intereface with bpu
    //input  pc_req_t                                     upstream_rxreq_pld          ,
    input req_addr_t                                    upstream_rxreq_addr,
    input logic [ICACHE_REQ_TXNID_WIDTH-1     :0]       upstream_rxreq_txnid,
    /////////end

    //downstream rxsnp
    input  logic                                        downstream_rxsnp_vld        ,
    output logic                                        downstream_rxsnp_rdy        ,
    input  pc_req_t                                     downstream_rxsnp_pld        ,

    //downtream txreq
    output logic                                        downstream_txreq_vld        ,
    input  logic                                        downstream_txreq_rdy        ,
    output pc_req_t                                     downstream_txreq_pld        ,

    output logic [MSHR_ENTRY_INDEX_WIDTH-1      :0]     downstream_txreq_entry_id      ,

    //downstream txrsp
    input  logic                                        downstream_txrsp_vld        ,
    output logic                                        downstream_txrsp_rdy        ,
    input  logic [ICACHE_REQ_OPCODE_WIDTH-1     :0]     downstream_txrsp_opcode     ,

    //downstream rxdat  in
    input  logic                                        downstream_rxdat_vld        ,
    output logic                                        downstream_rxdat_rdy        ,
    input  downstream_rxdat_t                           downstream_rxdat_pld        ,

    input logic                                               prefetch_req_vld            ,
    input pc_req_t                                            prefetch_req_pld            ,

    input  logic  pref_to_mshr_req_rdy


    );

    pc_req_t                                            upstream_rxreq_pld          ;
    assign upstream_rxreq_pld.addr  = upstream_rxreq_addr;
    assign upstream_rxreq_pld.txnid = upstream_rxreq_txnid;
    assign upstream_rxreq_pld.opcode= UPSTREAM_OPCODE;

    //logic                                               prefetch_req_vld            ;
    logic                                               prefetch_req_rdy            ;
    //pc_req_t                                            prefetch_req_pld            ;

    logic                                               tag_req_vld                 ;
    logic                                               tag_req_rdy                 ;
    pc_req_t                                            tag_req_pld                 ;
    logic                                               pre_tag_req_vld             ;
    pc_req_t                                            pre_tag_req_pld             ;
    logic                                               cre_tag_req_vld             ;


    logic                                               tag_miss                    ;
    logic [WAY_NUM-1                :0]                 tag_hit                     ;
    logic                                               lru_pick                    ;
    logic                                               mshr_stall                  ;

    logic                                               prefetch_en                 ;
    req_addr_t                                          miss_addr_for_prefetch      ;
    logic [ICACHE_REQ_TXNID_WIDTH-1 :0]                 miss_txnid_for_prefetch     ;
    //logic                                               pref_to_mshr_req_rdy        ;

    logic                                               dataram_rd_vld              ;
    logic                                               dataram_rd_rdy              ;
    logic                                               dataram_rd_way              ;
    logic [ICACHE_INDEX_WIDTH-1     :0]                 dataram_rd_index            ;
    logic [ICACHE_REQ_TXNID_WIDTH-1 :0]                 dataram_rd_txnid            ;

    mshr_entry_t                                        v_mshr_entry_array[MSHR_ENTRY_NUM-1:0];
    mshr_entry_t                                        mshr_entry_linefill_msg     ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1 :0]                 mshr_linefill_done_idx      ;
    logic                                               linefill_done               ;
    logic[MSHR_ENTRY_NUM-1          :0]                 v_linefill_done             ;
    logic [MSHR_ENTRY_INDEX_WIDTH :0]                   linefill_ack_entry_idx      ;

    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]                  alloc_index                 ;
    logic                                               alloc_vld                   ;
    logic                                               alloc_rdy                   ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]                  tag_req_idnex               ;
    logic                                               mshr_update_en              ;
    pc_req_t                                            mshr_update_pld             ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]                  req_index                   ;
    logic [MSHR_ENTRY_NUM-1:0]                          bitmap                      ;
    logic [MSHR_ENTRY_NUM-1:0]                          v_index_way_bitmap[MSHR_ENTRY_NUM-1:0];
    entry_data_t                                        entry_data                  ;
    dataram_rd_pld_t                                    rd_pld                      ;
    logic [MSHR_ENTRY_NUM-1        :0]                  v_index_way_release         ;
    logic [MSHR_ENTRY_NUM-1        :0]                  v_hit_entry_done            ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]                  entry_release_done_index    ;
    pc_req_t                                            req_pld                     ;
    logic [MSHR_ENTRY_NUM-1        :0]                  v_index_way_checkpass       ;
    logic                                               index_way_checkpass         ;
    logic [MSHR_ENTRY_NUM-1:0]                          v_mshr_entry_array_valid    ;

    icache_req_arbiter u_icache_req_arbiter (
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .upstream_rxreq_vld         (upstream_rxreq_vld         ),
        .upstream_rxreq_rdy         (upstream_rxreq_rdy         ),
        .upstream_rxreq_pld         (upstream_rxreq_pld         ),
        .downstream_rxsnp_vld       (downstream_rxsnp_vld       ),
        .downstream_rxsnp_rdy       (downstream_rxsnp_rdy       ),
        .downstream_rxsnp_pld       (downstream_rxsnp_pld       ),
        .prefetch_req_vld           (prefetch_req_vld           ),
        .prefetch_req_rdy           (prefetch_req_rdy           ),
        .prefetch_req_pld           (prefetch_req_pld           ),
        .alloc_vld                  (alloc_vld                  ),
        .alloc_rdy                  (alloc_rdy                  ),
        .alloc_index                (alloc_index                ),
        .tag_req_vld                (tag_req_vld                ),
        .tag_req_rdy                (tag_req_rdy                ),
        .tag_req_index              (tag_req_idnex              ),
        .tag_req_pld                (tag_req_pld                )
    );

    icache_tag_array_ctrl u_icache_tag_array_ctrl (
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .dataram_rd_rdy             (dataram_rd_rdy             ),
        .tag_req_vld                (tag_req_vld                ),
        .tag_req_rdy                (tag_req_rdy                ),
        .tag_req_pld                (tag_req_pld                ),
        .tag_req_index              (tag_req_idnex              ),
        .tag_miss                   (tag_miss                   ),
        .tag_hit                    (tag_hit                    ),
        .tag_way0_hit               (tag_way0_hit               ),
        .tag_way1_hit               (tag_way1_hit               ),
        .lru_pick                   (lru_pick                   ),
        .mshr_update_en             (mshr_update_en             ),
        .mshr_update_pld            (mshr_update_pld            ),
        .pre_tag_req_vld            (pre_tag_req_vld            ),
        .pre_tag_req_pld            (pre_tag_req_pld            ),
        .cre_tag_req_vld            (cre_tag_req_vld            ),
        .entry_release_done_index   (entry_release_done_index   ),
        .v_linefill_done            (v_linefill_done            ),
        .v_hit_entry_done           (v_hit_entry_done           ),
        .index_way_checkpass        (index_way_checkpass        ),
        .v_mshr_entry_array         (v_mshr_entry_array         ),
        .stall                      (mshr_stall                 ),
        .rd_vld                     (rd_vld                     ),
        .entry_data                 (entry_data                 ),
        .rd_pld                     (rd_pld                     ),
        .bitmap                     (bitmap                     ),
        .v_mshr_entry_array_valid   (v_mshr_entry_array_valid   )
    );

    icache_mshr_file u_icache_mshr_file (
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .prefetch_enable            (prefetch_enable            ),
        .pre_tag_req_vld            (pre_tag_req_vld            ),
        .pre_tag_req_pld            (pre_tag_req_pld            ),
        .tag_hit                    (tag_hit                    ),
        .tag_way0_hit               (tag_way0_hit               ),
        .tag_way1_hit               (tag_way1_hit               ),
        .tag_miss                   (tag_miss                   ),
        .lru_pick                   (lru_pick                   ),
        .mshr_update_en             (mshr_update_en             ),
        .mshr_update_pld            (mshr_update_pld            ),
        .alloc_vld                  (alloc_vld                  ),
        .alloc_rdy                  (alloc_rdy                  ),
        .alloc_index                (alloc_index                ),

        .mshr_stall                 (mshr_stall                 ),
        .pref_to_mshr_req_rdy       (pref_to_mshr_req_rdy       ),
        //.miss_addr_for_prefetch     (miss_addr_for_prefetch     ),
        //.miss_txnid_for_prefetch    (miss_txnid_for_prefetch    ),
        //.miss_for_prefetch          (prefetch_en                ),
        .miss_addr_for_prefetch     (                           ),
        .miss_txnid_for_prefetch    (                           ),
        .miss_for_prefetch          (                           ),
        .dataram_rd_vld             (dataram_rd_vld             ),
        .dataram_rd_rdy             (dataram_rd_rdy             ),
        .dataram_rd_way             (dataram_rd_way             ),
        .dataram_rd_index           (dataram_rd_index           ),
        .dataram_rd_txnid           (dataram_rd_txnid           ),
        .downstream_txreq_vld       (downstream_txreq_vld       ),
        .downstream_txreq_rdy       (downstream_txreq_rdy       ),
        .downstream_txreq_pld       (downstream_txreq_pld       ),
        .downstream_txreq_entry_id  (downstream_txreq_entry_id  ),
        .downstream_txrsp_vld       (downstream_txrsp_vld       ),
        .downstream_txrsp_rdy       (downstream_txrsp_rdy       ),
        .downstream_txrsp_opcode    (downstream_txrsp_opcode    ),

        .v_mshr_entry_array         (v_mshr_entry_array         ),
        .linefill_ack_entry_idx     (linefill_ack_entry_idx     ),
        .linefill_done              (linefill_done              ),

        .entry_release_done_index   (entry_release_done_index   ),
        .v_linefill_done            (v_linefill_done            ),
        .v_hit_entry_done           (v_hit_entry_done           ),
        .index_way_checkpass        (index_way_checkpass        ),
        .rd_vld                     (rd_vld                     ),
        .entry_data                 (entry_data                 ),
        .rd_pld                     (rd_pld                     ),
        .v_mshr_entry_array_valid   (v_mshr_entry_array_valid   ),
        .bitmap                     (bitmap                     )
    );


//dataarray ctrl with linefill in
    icache_data_array_ctrl u_data_array_ctrl(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .dataram_rd_vld             (dataram_rd_vld             ),
        .dataram_rd_rdy             (dataram_rd_rdy             ),
        .dataram_rd_way             (dataram_rd_way             ),
        .dataram_rd_index           (dataram_rd_index           ),
        .dataram_rd_txnid           (dataram_rd_txnid           ),
        .mshr_entry_array_msg       (v_mshr_entry_array         ),
        .linefill_ack_entry_idx     (linefill_ack_entry_idx     ),
        .linefill_done              (linefill_done              ),
        .downstream_rxdat_vld       (downstream_rxdat_vld       ),
        .downstream_rxdat_rdy       (downstream_rxdat_rdy       ),
        .downstream_rxdat_pld       (downstream_rxdat_pld       ),
        .upstream_txdat_data        (upstream_txdat_data        ),
        .upstream_txdat_vld         (upstream_txdat_vld         ),
        .upstream_txdat_txnid       (upstream_txdat_txnid       )
    );

    //icache_prefetch_engine u_prefetch_engine (
    //    .clk                        (clk                        ),
    //    .rst_n                      (rst_n                      ),
    //    .miss_for_prefetch          (prefetch_en                ),
    //    .miss_addr_for_prefetch     (miss_addr_for_prefetch     ),
    //    .miss_txnid_for_prefetch    (miss_txnid_for_prefetch    ),
    //    .pref_to_mshr_req_rdy       (pref_to_mshr_req_rdy       ),
    //    .prefetch_req_vld           (prefetch_req_vld           ),
    //    .prefetch_req_rdy           (prefetch_req_rdy           ),
    //    .prefetch_req_pld           (prefetch_req_pld           )
    //);


endmodule