module icache_req_arbiter
    import toy_pack::*;
    (
    input  logic                 clk                      ,
    input  logic                 rst_n                    ,
  
    input  logic                 upstream_rxreq_vld       ,
    output logic                 upstream_rxreq_rdy       ,
    input  pc_req_t              upstream_rxreq_pld       ,
  
    input  logic                 downstream_rxsnp_vld     ,
    output logic                 downstream_rxsnp_rdy     ,
    input  pc_req_t              downstream_rxsnp_pld     ,

    input  logic                 prefetch_req_vld         ,
    output logic                 prefetch_req_rdy         ,
    input  pc_req_t              prefetch_req_pld         ,
  
    input  logic                 alloc_vld                ,
    input  logic[MSHR_ENTRY_INDEX_WIDTH-1:0] alloc_index  ,
    output logic                 alloc_rdy                ,

    output logic                 tag_req_vld              ,
    input  logic                 tag_req_rdy              ,
    output logic [MSHR_ENTRY_INDEX_WIDTH-1:0]tag_req_index,
    output pc_req_t              tag_req_pld
    );
    localparam PLD_WIDTH = $bits(pc_req_t);
    
    logic [2    :0]              v_vld_s                ;
    logic [2    :0]              v_rdy_s                ;
    pc_req_t                     v_pld_s[2:0]           ;
    logic [2    :0]              select_onehot          ;
    logic                        vld_m                  ;
    pc_req_t                     pld_m                  ;
    logic                        rdy_m                  ;

    assign rdy_m            = tag_req_rdy                                                       ;      
    assign v_vld_s          = {prefetch_req_vld, downstream_rxsnp_vld, upstream_rxreq_vld}      ;
    assign v_pld_s[0]       = upstream_rxreq_pld                                                ;
    assign v_pld_s[1]       = downstream_rxsnp_pld                                              ;
    assign v_pld_s[2]       = prefetch_req_pld                                                  ;
    //assign upstream_rxreq_rdy = alloc_vld && upstream_rxreq_vld && tag_req_rdy;
    //assign downstream_rxsnp_rdy= 0;
    //assign prefetch_req_rdy    = 0;
    assign {prefetch_req_rdy, downstream_rxsnp_rdy, upstream_rxreq_rdy} = v_rdy_s && {3{alloc_vld}};
    //fix_priority_arb #(
    //    .WIDTH      (3          ),
    //    .PLD_TYPE   (pc_req_t   )
    //) arbiter (
    //    .v_vld_s    (v_vld_s    ),
    //    .v_rdy_s    (v_rdy_s    ),
    //    .v_pld_s    (v_pld_s    ),
    //    .vld_m      (vld_m      ),
    //    .rdy_m      (rdy_m      ),
    //    .pld_m      (pld_m      )
    //);
    vrp_arb #(
        .WIDTH      (3          ),
        .PLD_WIDTH  ($bits(pc_req_t))
    ) arbiter (
        .v_vld_s    (v_vld_s    ),
        .v_rdy_s    (v_rdy_s    ),
        .v_pld_s    (v_pld_s    ),
        .vld_m      (vld_m      ),
        .rdy_m      (rdy_m      ),
        .pld_m      (pld_m      )
    );

   
    assign tag_req_vld      = vld_m  && alloc_vld;          
    assign tag_req_pld      = pld_m              ;
    assign tag_req_index    = alloc_index        ;
    //assign alloc_rdy        = tag_req_vld && tag_req_rdy;
    assign alloc_rdy        = tag_req_vld        ;

endmodule