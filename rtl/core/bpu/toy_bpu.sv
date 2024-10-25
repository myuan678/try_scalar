module toy_bpu
   import toy_pack::*;
   (
      input    logic                                      clk,
      input    logic                                      rst_n,

      output   logic                                      icache_req_vld,
      output   logic           [ROB_ENTRY_ID_WIDTH-1:0]   icache_req_entry_id,
      output   logic           [ADDR_WIDTH-1:0]           icache_req_addr,
      input    logic                                      icache_req_rdy,
      input    logic                                      icache_ack_vld,
      output   logic                                      icache_ack_rdy,
      input    logic           [FETCH_DATA_WIDTH-1:0]     icache_ack_pld,
      input    logic           [ROB_ENTRY_ID_WIDTH-1:0]   icache_ack_entry_id,

      input    logic                                      fetch_queue_rdy,
      output   logic                                      fetch_queue_vld,
      output   fetch_queue_pkg                            fetch_queue_pld     [FILTER_CHANNEL-1:0],
      output   logic           [FILTER_CHANNEL-1:0]       fetch_queue_en,

      input    logic           [COMMIT_CHANNEL-1:0]       be_commit_vld,
      input    be_pkg                                     be_commit_pld       [COMMIT_CHANNEL-1:0],
      input    logic                                      be_cancel_en,
      input    logic                                      be_cancel_edge,
      input    logic           [COMMIT_CHANNEL-1 :0]      be_commit_error_en,
      input    be_pkg                                     be_cancel_pld       [COMMIT_CHANNEL-1:0]


   );
   //==============================================================
   // interface
   //==============================================================
   // chgflw
   logic                                              pcgen_stall;
   logic                                              pcgen_chgflw_vld;
   bpu_pkg                                            pcgen_chgflw_pld;
   logic                                              pcgen_chgflw_rdy;
   logic                                              l0btb_chgflw;
   bpu_pkg                                            l0btb_chgflw_pld;
   bpu_pkg                                            l0btb_pred_pld;
   logic                                              l0btb_pred_vld;
   logic                                              tage_flush;
   logic                                              btb_bp2_chgflw_vld;
   logic                                              btb_be_flush;
   logic                                              btb_ras_flush;
   logic                                              btb_chgflw;
   logic    [ADDR_WIDTH-1:0]                          btb_chgflw_pld;
   logic                                              btb_enqueue;
   logic    [ADDR_WIDTH-1:0]                          btb_enqueue_pld;
   logic                                              ghr_chgflw;
   logic                                              ghr_chgflw_taken;
   logic                                              ghr_flush;

   logic                                              bpdec_be_flush;
   logic                                              bpdec_ras_flush;
   logic                                              bpdec_chgflw_vld;
   bpu_update_pkg                                     bpdec_chgflw_pld;
   logic                                              bpdec_enqueue;
   logic                                              bpdec_entry_buffer_rdy;
   logic                                              bpdec_bp2_chgflw_vld_sm;
   logic                                              bpdec_bp2_chgflw_vld_s0;
   bpu_pkg                                            bpdec_bp2_chgflw_pld_s0;
   logic                                              btfifo_flush;
   logic                                              rob_bp2_vld;
   logic                                              rob_bp2_flush;
   logic                                              rob_flush;
   logic                                              rob_flush_done;
   logic                                              rob_rdy;
   logic                                              ras_flush;
   logic                                              ras_chgflw;
   ras_pkg                                            ras_chgflw_pld;
   bpu_pkg                                            ras_ret_pld;
   logic                                              ras_ret_chgflw;
   logic                                              filter_be_chgflw;
   logic                                              filter_enqueue;
   logic          [ADDR_WIDTH-1:0]                    filter_enqueue_pld;

   // pcgen
   logic                                              rob_prealloc_req;
   logic [ROB_ENTRY_ID_WIDTH-1:0]                     rob_prealloc_entry_id;
   logic                                              pcgen_l0btb_vld;
   logic [ADDR_WIDTH-1:0]                             pcgen_l0btb_pc;
   logic                                              pcgen_btb_vld;
   logic [ADDR_WIDTH-1:0]                             pcgen_btb_pc;
   logic                                              pcgen_tage_vld;
   logic [ADDR_WIDTH-1:0]                             pcgen_tage_pc;

   // bpdec
   logic                                              bpdec_l0btb_vld;
   bpu_pkg                                            bpdec_l0btb_pld;
   logic                                              bpdec_tage_vld;
   tage_pkg                                           bpdec_tage_pld;
   logic                                              bpdec_tage_w_vld;
   logic                                              bpdec_tage_w_rdy;
   tage_entry_buffer_pkg                              bpdec_tage_w_pld;
   logic                                              bpdec_btb_vld;
   btb_pkg                                            bpdec_btb_pld;
   btb_entry_buffer_pkg                               bpdec_entry_buffer_pld    [ENTRY_BUFFER_NUM-1:0];
   logic                 [ENTRY_BUFFER_PTR_WIDTH:0]   bpdec_entry_buffer_ptr;
   logic                 [ENTRY_BUFFER_NUM-1:0]       bpdec_entry_buffer_ena;
   logic                                              bpdec_btb_w_vld;
   logic                                              bpdec_btb_w_rdy;
   btb_entry_buffer_pkg                               bpdec_btb_w_pld;
   logic                                              bpdec_fifo_bp2_vld;
   logic                                              bpdec_fifo_bp2_chgflw;
   bpu_pkg                                            bpdec_fifo_bp2_chgflw_pld;


   // ghr
   logic                                              ghr_bpu_pred_vld;
   logic                                              ghr_bpu_pred_taken;
   logic [GHR_LENGTH-1:0]                             ghr_bpu_ghr;
   logic                                              ghr_enqueue;
   logic                                              ghr_enqueue_taken;
   logic                                              ghr_ras_flush;
   logic                                              ghr_pending;
   logic                                              ghr_pending_taken;


   // filter
   logic                                              filter_btfifo_rdy;
   logic                                              filter_btfifo_vld;
   bpu_pkg                                            filter_btfifo_pld;
   logic                                              filter_rob_rdy;
   logic                                              filter_rob_vld;
   logic   [FETCH_DATA_WIDTH-1:0]                     filter_rob_pld;
   logic                                              filter_ras_req_vld;
   ras_pkg                                            filter_ras_req_pld;
   logic                                              filter_ras_chgflw;
   bpu_pkg                                            filter_ras_pld;

   // mem model
   logic                                              tb_mem_req_wren;
   logic                                              tb_mem_req_vld;
   logic [TAGE_BASE_INDEX_WIDTH-1:0]                  tb_mem_req_addr;
   logic [TAGE_BASE_PRED_WIDTH-1:0]                   tb_mem_req_wdata;
   logic [TAGE_BASE_PRED_WIDTH-1:0]                   tb_mem_ack_rdata;

   logic             [TAGE_TABLE_NUM-1:0]             tx_mem_req_vld;
   logic             [TAGE_TABLE_NUM-1:0]             tx_mem_req_wren;
   logic             [TAGE_TX_INDEX_WIDTH-1:0]        tx_mem_req_addr  [TAGE_TABLE_NUM-1:0];
   tage_tx_field_pkg                                  tx_mem_req_wdata [TAGE_TABLE_NUM-1:0];
   tage_tx_field_pkg                                  tx_mem_ack_rdata [TAGE_TABLE_NUM-1:0];

   logic                                              btb_mem_req_vld;
   logic         [BTB_WAY_NUM-1:0]                    btb_mem_req_wren;
   logic         [BTB_INDEX_WIDTH-1:0]                btb_mem_req_addr;
   btb_entry_pkg                                      btb_mem_req_wdata;
   btb_entry_pkg                                      btb_mem_ack_rdata;


   //==============================================================
   // commit extra: TODO delete this part
   //==============================================================
   be_pkg  be_cancel_sel_pld;

   cmn_real_mux_onehot #(
      .PLD_WIDTH($bits(be_pkg)                              ),
      .WIDTH    (COMMIT_CHANNEL                             )
   ) u_sel_cmt (
      .select_onehot(be_commit_error_en                     ),
      .select_pld   (be_cancel_sel_pld                      ),
      .v_pld        (be_cancel_pld                          )
   );


   //==============================================================
   // instance module
   //==============================================================

   toy_bpu_mem u_mem(
      .clk              (clk                                ),
      .rst_n            (rst_n                              ),
      .tb_mem_req_vld   (tb_mem_req_vld                     ),
      .tb_mem_req_wren  (tb_mem_req_wren                    ),
      .tb_mem_req_addr  (tb_mem_req_addr                    ),
      .tb_mem_req_wdata (tb_mem_req_wdata                   ),
      .tb_mem_ack_rdata (tb_mem_ack_rdata                   ),
      .tx_mem_req_vld   (tx_mem_req_vld                     ),
      .tx_mem_req_wren  (tx_mem_req_wren                    ),
      .tx_mem_req_addr  (tx_mem_req_addr                    ),
      .tx_mem_req_wdata (tx_mem_req_wdata                   ),
      .tx_mem_ack_rdata (tx_mem_ack_rdata                   ),
      .btb_mem_req_vld  (btb_mem_req_vld                    ),
      .btb_mem_req_wren (btb_mem_req_wren                   ),
      .btb_mem_req_addr (btb_mem_req_addr                   ),
      .btb_mem_req_wdata(btb_mem_req_wdata                  ),
      .btb_mem_ack_rdata(btb_mem_ack_rdata                  )
   );

   // toy_pcgen u_pcgen(
   //    .clk                  (clk                            ),
   //    .rst_n                (rst_n                          ),
   //    .fe_ctrl_stall        (pcgen_stall                    ),
   //    .fe_ctrl_chgflw_vld   (pcgen_chgflw_vld               ),
   //    .fe_ctrl_chgflw_pld   (pcgen_chgflw_pld               ),
   //    .fe_ctrl_chgflw_rdy   (pcgen_chgflw_rdy               ),
   //    .rob_prealloc_req     (rob_prealloc_req               ),
   //    .rob_prealloc_entry_id(rob_prealloc_entry_id          ),
   //    .icache_req_vld       (icache_req_vld                 ),
   //    .icache_req_entry_id  (icache_req_entry_id            ),
   //    .icache_req_addr      (icache_req_addr                ),
   //    .icache_req_rdy       (icache_req_rdy                 ),
   //    .pcgen_l0btb_vld      (pcgen_l0btb_vld                ),
   //    .pcgen_l0btb_pc       (pcgen_l0btb_pc                 ),
   //    .pcgen_btb_vld        (pcgen_btb_vld                  ),
   //    .pcgen_btb_pc         (pcgen_btb_pc                   ),
   //    .pcgen_tage_vld       (pcgen_tage_vld                 ),
   //    .pcgen_tage_pc        (pcgen_tage_pc                  )
   // );

   toy_bpu_l0btb u_l0btb(
      .clk                     (clk                               ),
      .rst_n                   (rst_n                             ),
      .pcgen_vld               (pcgen_l0btb_vld                   ),
      .pcgen_pc                (pcgen_l0btb_pc                    ),
      .bpdec_l0btb_vld         (bpdec_l0btb_vld                   ),
      .bpdec_l0btb_pld         (bpdec_l0btb_pld                   ),
      .fe_ctrl_chgflw_vld_i    (l0btb_chgflw                      ),
      .fe_ctrl_chgflw_pld_i    (l0btb_chgflw_pld                  ),
      .fe_ctrl_chgflw_pld_o    (l0btb_pred_pld                    ),
      .fe_ctrl_chgflw_vld_o    (l0btb_pred_vld                    )
   );

   toy_bpu_tage u_tage (
      .clk                   (clk                                ),
      .rst_n                 (rst_n                              ),
      .pcgen_vld             (pcgen_tage_vld                     ),
      .pcgen_pc              (pcgen_tage_pc                      ),
      .ghr                   (ghr_bpu_ghr                        ),
      .tb_mem_req_vld        (tb_mem_req_vld                     ),
      .tb_mem_req_wren       (tb_mem_req_wren                    ),
      .tb_mem_req_addr       (tb_mem_req_addr                    ),
      .tb_mem_req_wdata      (tb_mem_req_wdata                   ),
      .tb_mem_ack_rdata      (tb_mem_ack_rdata                   ),
      .tx_mem_req_vld        (tx_mem_req_vld                     ),
      .tx_mem_req_wren       (tx_mem_req_wren                    ),
      .tx_mem_req_addr       (tx_mem_req_addr                    ),
      .tx_mem_req_wdata      (tx_mem_req_wdata                   ),
      .tx_mem_ack_rdata      (tx_mem_ack_rdata                   ),
      .bpdec_tage_vld        (bpdec_tage_vld                     ),
      .bpdec_tage_pld        (bpdec_tage_pld                     ),
      .bpdec_tage_update_vld (bpdec_tage_w_vld                   ),
      .bpdec_tage_update_rdy (bpdec_tage_w_rdy                   ),
      .bpdec_tage_update_pld (bpdec_tage_w_pld                   ),
      .fe_ctrl_flush         (tage_flush                         )
   );

   toy_bpu_btb u_btb (
      .clk                          (clk                                 ),
      .rst_n                        (rst_n                               ),
      .pcgen_vld                    (pcgen_btb_vld                       ),
      .pcgen_pc                     (pcgen_btb_pc                        ),
      .mem_req_vld                  (btb_mem_req_vld                     ),
      .mem_req_wren                 (btb_mem_req_wren                    ),
      .mem_req_addr                 (btb_mem_req_addr                    ),
      .mem_req_wdata                (btb_mem_req_wdata                   ),
      .mem_ack_rdata                (btb_mem_ack_rdata                   ),
      .bpdec_btb_vld                (bpdec_btb_vld                       ),
      .bpdec_btb_pld                (bpdec_btb_pld                       ),
      .bpdec_entry_buffer_pld       (bpdec_entry_buffer_pld              ),
      .bpdec_entry_buffer_ptr       (bpdec_entry_buffer_ptr              ),
      .bpdec_entry_buffer_ena       (bpdec_entry_buffer_ena              ),
      .bpdec_btb_update_vld         (bpdec_btb_w_vld                     ),
      .bpdec_btb_update_rdy         (bpdec_btb_w_rdy                     ),
      .bpdec_btb_update_pld         (bpdec_btb_w_pld                     ),
      .fe_ctrl_bp2_chgflw_vld       (btb_bp2_chgflw_vld                  ),
      .fe_ctrl_be_flush             (btb_be_flush                        ),
      .fe_ctrl_be_chgflw_vld        (btb_chgflw                          ),
      .fe_ctrl_be_chgflw_pld        (btb_chgflw_pld                      ),
      .fe_ctrl_ras_flush            (btb_ras_flush                       ),
      .fe_ctrl_ras_enqueue_vld      (btb_enqueue                         ),
      .fe_ctrl_ras_enqueue_pld      (btb_enqueue_pld                     )
   );

   toy_bpu_ghr u_ghr (
      .clk                          (clk                            ),
      .rst_n                        (rst_n                          ),
      .bpu_pred_vld                 (ghr_bpu_pred_vld               ),
      .bpu_pred_taken               (ghr_bpu_pred_taken             ),
      .bpu_ghr                      (ghr_bpu_ghr                    ),
      .fe_ctrl_be_chgflw_vld        (ghr_chgflw                     ),
      .fe_ctrl_be_chgflw_taken      (ghr_chgflw_taken               ),
      .fe_ctrl_be_flush             (ghr_flush                      ),
      .fe_ctrl_ras_enqueue_vld      (ghr_enqueue                    ),
      .fe_ctrl_ras_enqueue_taken    (ghr_enqueue_taken              ),
      .fe_ctrl_ras_flush            (ghr_ras_flush                  )
   );

   toy_bpu_ras u_ras (
      .clk               (clk                               ),
      .rst_n             (rst_n                             ),
      .filter_vld        (filter_ras_req_vld                ),
      .filter_pld        (filter_ras_req_pld                ),
      .fe_ctrl_flush     (ras_flush                         ),
      .fe_ctrl_chgflw    (ras_chgflw                        ),
      .fe_ctrl_chgflw_pld(ras_chgflw_pld                    ),
      .fe_ctrl_ras_pld   (ras_ret_pld                       ),
      .fe_ctrl_ras_chgflw(ras_ret_chgflw                    )
   );



   toy_bpu_bpdec u_bpdec (
      .clk                              (clk                            ),
      .rst_n                            (rst_n                          ),
      .l0btb_vld                        (bpdec_l0btb_vld                ),
      .l0btb_pld                        (bpdec_l0btb_pld                ),
      .tage_vld                         (bpdec_tage_vld                 ),
      .tage_pld                         (bpdec_tage_pld                 ),
      .tage_w_vld                       (bpdec_tage_w_vld               ),
      .tage_w_rdy                       (bpdec_tage_w_rdy               ),
      .tage_w_pld                       (bpdec_tage_w_pld               ),
      .btb_vld                          (bpdec_btb_vld                  ),
      .btb_pld                          (bpdec_btb_pld                  ),
      .btb_bypass_pld                   (bpdec_entry_buffer_pld         ),
      .btb_bypass_ptr                   (bpdec_entry_buffer_ptr         ),
      .btb_bypass_ena                   (bpdec_entry_buffer_ena         ),
      .btb_w_vld                        (bpdec_btb_w_vld                ),
      .btb_w_rdy                        (bpdec_btb_w_rdy                ),
      .btb_w_pld                        (bpdec_btb_w_pld                ),
      .ghr_taken                        (ghr_bpu_pred_taken             ),
      .ghr_vld                          (ghr_bpu_pred_vld               ),
      .fifo_bp2_vld                     (bpdec_fifo_bp2_vld             ),
      .fifo_bp2_chgflw_vld              (bpdec_fifo_bp2_chgflw          ),
      .fifo_bp2_chgflw_pld              (bpdec_fifo_bp2_chgflw_pld      ),
      .rob_bp2_vld                      (rob_bp2_vld                    ),
      .rob_bp2_flush                    (rob_bp2_flush                  ),
      .fe_ctrl_be_flush                 (btb_be_flush                   ),
      .fe_ctrl_ras_flush                (btb_ras_flush                  ),
      .fe_ctrl_be_chgflw_vld            (bpdec_chgflw_vld               ),
      .fe_ctrl_be_chgflw_pld            (bpdec_chgflw_pld               ),
      .fe_ctrl_ras_enqueue_vld          (bpdec_enqueue                  ),
      .fe_ctrl_entry_buffer_rdy         (bpdec_entry_buffer_rdy         ),
      .fe_ctrl_bp2_chgflw_vld           (bpdec_bp2_chgflw_vld_s0        ),
      .fe_ctrl_bp2_chgflw_pld           (bpdec_bp2_chgflw_pld_s0        )
   );

   toy_bpu_btfifo u_btfifo (
      .clk                 (clk                             ),
      .rst_n               (rst_n                           ),
      .bpdec_bp2_vld       (bpdec_fifo_bp2_vld              ),
      .bpdec_bp2_chgflw    (bpdec_fifo_bp2_chgflw           ),
      .bpdec_bp2_chgflw_pld(bpdec_fifo_bp2_chgflw_pld       ),
      .filter_rdy          (filter_btfifo_rdy               ),
      .filter_vld          (filter_btfifo_vld               ),
      .filter_pld          (filter_btfifo_pld               ),
      .fe_ctrl_flush       (btfifo_flush                    )
   );

   toy_bpu_rob u_rob (
      .clk                 (clk                             ),
      .rst_n               (rst_n                           ),
      .pcgen_req           (rob_prealloc_req                ),
      .pcgen_ack_entry_id  (rob_prealloc_entry_id           ),
      .icache_ack_vld      (icache_ack_vld                  ),
      .icache_ack_rdy      (icache_ack_rdy                  ),
      .icache_ack_pld      (icache_ack_pld                  ),
      .icache_ack_entry_id (icache_ack_entry_id             ),
      .filter_vld          (filter_rob_vld                  ),
      .filter_rdy          (filter_rob_rdy                  ),
      .filter_pld          (filter_rob_pld                  ),
      .bpdec_bp2_vld       (rob_bp2_vld                     ),
      .bpdec_bp2_flush     (rob_bp2_flush                   ),
      .fe_ctrl_flush       (rob_flush                       ),
      .fe_ctrl_flush_done  (rob_flush_done                  ),
      .fe_ctrl_rdy         (rob_rdy                         )
   );

   toy_bpu_filter u_fillter (
      .clk                (clk                              ),
      .rst_n              (rst_n                            ),
      .btfifo_rdy         (filter_btfifo_rdy                ),
      .btfifo_vld         (filter_btfifo_vld                ),
      .btfifo_pld         (filter_btfifo_pld                ),
      .rob_rdy            (filter_rob_rdy                   ),
      .rob_vld            (filter_rob_vld                   ),
      .rob_pld            (filter_rob_pld                   ),
      .ras_req_vld        (filter_ras_req_vld               ),
      .ras_req_pld        (filter_ras_req_pld               ),
      .fetch_queue_rdy    (fetch_queue_rdy                  ),
      .fetch_queue_vld    (fetch_queue_vld                  ),
      .fetch_queue_pld    (fetch_queue_pld                  ),
      .fetch_queue_en     (fetch_queue_en                   ),
      .fe_ctrl_be_chgflw  (filter_be_chgflw                 ),
      .fe_ctrl_ras_chgflw (filter_ras_chgflw                ),
      .fe_ctrl_ras_pld    (filter_ras_pld                   ),
      .fe_ctrl_enqueue    (filter_enqueue                   ),
      .fe_ctrl_enqueue_pld(filter_enqueue_pld               )
   );



   toy_fe_ctrl u_fe_ctrl (
      .clk                                (clk                                          ),
      .rst_n                              (rst_n                                        ),
      .icache_req_vld                     (icache_req_vld                               ),
      .icache_req_entry_id                (icache_req_entry_id                          ),
      .icache_req_addr                    (icache_req_addr                              ),
      .icache_req_rdy                     (icache_req_rdy                               ),
      .l0btb_pred_vld                     (pcgen_l0btb_vld                              ),
      .l0btb_pred_pc                      (pcgen_l0btb_pc                               ),
      .l0btb_chgflw_vld_o                 (l0btb_chgflw                                 ),
      .l0btb_chgflw_pld_o                 (l0btb_chgflw_pld                             ),
      .l0btb_chgflw_pld_i                 (l0btb_pred_pld                               ),
      .l0btb_chgflw_vld_i                 (l0btb_pred_vld                               ),
      .tage_pred_vld                      (pcgen_tage_vld                               ),
      .tage_pred_pc                       (pcgen_tage_pc                                ),
      .tage_flush                         (tage_flush                                   ),
      .btb_pred_vld                       (pcgen_btb_vld                                ),
      .btb_pred_pc                        (pcgen_btb_pc                                 ),
      .btb_bp2_chgflw_vld                 (btb_bp2_chgflw_vld                           ),
      .btb_be_flush                       (btb_be_flush                                 ),
      .btb_be_chgflw_vld                  (btb_chgflw                                   ),
      .btb_be_chgflw_pld                  (btb_chgflw_pld                               ),
      .btb_ras_flush                      (btb_ras_flush                                ),
      .btb_ras_enqueue_vld                (btb_enqueue                                  ),
      .btb_ras_enqueue_pld                (btb_enqueue_pld                              ),
      .ghr_be_chgflw_vld                  (ghr_chgflw                                   ),
      .ghr_be_chgflw_taken                (ghr_chgflw_taken                             ),
      .ghr_be_flush                       (ghr_flush                                    ),
      .ghr_ras_enqueue_vld                (ghr_enqueue                                  ),
      .ghr_ras_enqueue_taken              (ghr_enqueue_taken                            ),
      .ghr_ras_flush                      (ghr_ras_flush                                ),
      .bpdec_be_flush                     (bpdec_be_flush                               ),
      .bpdec_ras_flush                    (bpdec_ras_flush                              ),
      .bpdec_be_chgflw_vld                (bpdec_chgflw_vld                             ),
      .bpdec_be_chgflw_pld                (bpdec_chgflw_pld                             ),
      .bpdec_ras_enqueue_vld              (bpdec_enqueue                                ),
      .bpdec_entry_buffer_rdy             (bpdec_entry_buffer_rdy                       ),
      .bpdec_bp2_chgflw_vld               (bpdec_bp2_chgflw_vld_s0                      ),
      .bpdec_bp2_chgflw_pld               (bpdec_bp2_chgflw_pld_s0                      ),
      .btfifo_flush                       (btfifo_flush                                 ),
      .rob_prealloc_req                   (rob_prealloc_req                             ),
      .rob_prealloc_entry_id              (rob_prealloc_entry_id                        ),
      .rob_flush                          (rob_flush                                    ),
      .rob_rdy                            (rob_rdy                                      ),
      .ras_flush                          (ras_flush                                    ),
      .ras_vld                            (ras_chgflw                                   ),
      .ras_pld                            (ras_chgflw_pld                               ),
      .ras_chgflw_pld                     (ras_ret_pld                                  ),
      .ras_chgflw_vld                     (ras_ret_chgflw                               ),
      .filter_be_chgflw_vld               (filter_be_chgflw                             ),
      .filter_ras_chgflw_vld              (filter_ras_chgflw                            ),
      .filter_ras_chgflw_pld              (filter_ras_pld                               ),
      .filter_enqueue_vld                 (filter_enqueue                               ),
      .filter_enqueue_pld                 (filter_enqueue_pld                           ),
      .be_commit_vld                      (be_commit_vld                                ),
      .be_commit_pld                      (be_commit_pld                                ),
      .be_cancel_en                       (be_commit_error_en                           ),
      .be_cancel_edge                     (be_cancel_edge                               ),
      .be_cancel_pld                      (be_cancel_sel_pld                            )
   );


endmodule 