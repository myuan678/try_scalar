module icache_data_array_ctrl 
    import toy_pack::*;
    (
    input  logic                                        clk                                     ,
    input  logic                                        rst_n                                   ,
    input  mshr_entry_t                                 mshr_entry_array_msg[MSHR_ENTRY_NUM-1:0],

    input  logic                                        dataram_rd_vld                          ,
    output logic                                        dataram_rd_rdy                          ,
    input  logic                                        dataram_rd_way                          ,
    input  logic  [ICACHE_INDEX_WIDTH-1         :0]     dataram_rd_index                        ,
    input  logic  [ICACHE_REQ_TXNID_WIDTH-1     :0]     dataram_rd_txnid                        ,

    input  logic                                        downstream_rxdat_vld                    ,
    output logic                                        downstream_rxdat_rdy                    ,
    input  downstream_rxdat_t                           downstream_rxdat_pld                    ,  //downstream_rxdat_pld 
    output logic [MSHR_ENTRY_INDEX_WIDTH        :0]     linefill_ack_entry_idx                  ,
    output logic                                        linefill_done                           ,
    output logic [ICACHE_UPSTREAM_DATA_WIDTH-1  :0]     upstream_txdat_data                     ,
    output logic                                        upstream_txdat_vld                      ,
    output logic [ICACHE_REQ_TXNID_WIDTH-1      :0]     upstream_txdat_txnid             
    );


    logic                                               data_array_wr_en                        ;
    logic       [ICACHE_INDEX_WIDTH             :0]     data_array_addr                         ;
    logic       [ICACHE_DATA_WIDTH/2-1          :0]     data_array0_dout                        ;
    logic       [ICACHE_DATA_WIDTH/2-1          :0]     data_array1_dout                        ;
    logic       [ICACHE_DATA_WIDTH/2-1          :0]     data_array0_din                         ;
    logic       [ICACHE_DATA_WIDTH/2-1          :0]     data_array1_din                         ;
    logic       [MSHR_ENTRY_INDEX_WIDTH-1       :0]     downstream_rxdat_entry_idx              ;
    logic       [ICACHE_DATA_WIDTH-1            :0]     linefill_data                           ;
    logic       [ICACHE_REQ_TXNID_WIDTH-1       :0]     linefill_done_txnid                     ;
    logic       [ICACHE_REQ_TXNID_WIDTH-1       :0]     dataram_rd_txnid_out                    ;
    logic                                               dataram_dout_vld                        ;
    logic                                               mem_en                                  ; 
    logic                                               uptxdat_en                              ;
    logic                                               linefill_data_vld                       ;

    
    assign uptxdat_en = downstream_rxdat_pld.downstream_rxdat_opcode == UPSTREAM_OPCODE         ;
    assign mem_en                       = (dataram_rd_vld && dataram_rd_rdy) | linefill_done    ;
    assign downstream_rxdat_entry_idx   = downstream_rxdat_pld.downstream_rxdat_entry_idx       ;
    //assign dataram_rd_rdy               = (linefill_done == 1'b0)                               ;
    assign dataram_rd_rdy               = (downstream_rxdat_vld==1'b0);
    
    //always_ff@(posedge clk or negedge rst_n) begin
    //    if(!rst_n)begin
    //        downstream_rxdat_rdy     <= 1'b0;
    //    end
    //    else if(downstream_rxdat_vld )begin
    //        downstream_rxdat_rdy     <= 1'b1;
    //    end
    //    else begin
    //        downstream_rxdat_rdy     <= 1'b0;
    //    end
    //end
    always_comb begin
        
        if(downstream_rxdat_vld )begin
            downstream_rxdat_rdy     = 1'b1;
        end
        else begin
            downstream_rxdat_rdy     = 1'b0;
        end
    end

    assign linefill_done            = downstream_rxdat_vld && downstream_rxdat_rdy;
    assign linefill_ack_entry_idx   = downstream_rxdat_pld.downstream_rxdat_entry_idx;
    
    always_ff @(posedge clk )begin   
        if(linefill_done)begin
            linefill_data_vld <= 1'b1;
            linefill_data <= downstream_rxdat_pld.downstream_rxdat_data;
        end
        else begin
            linefill_data_vld <= 1'b0;
            linefill_data <= 'b0;
        end
    end


    assign data_array0_din      = downstream_rxdat_pld.downstream_rxdat_data[ICACHE_DATA_WIDTH/2-1:0];
    assign data_array1_din      = downstream_rxdat_pld.downstream_rxdat_data[ICACHE_DATA_WIDTH-1:ICACHE_DATA_WIDTH/2];
    assign data_array_wr_en     = linefill_done;
    assign data_array_addr      = linefill_done ? {mshr_entry_array_msg[downstream_rxdat_entry_idx].req_pld.addr.index,mshr_entry_array_msg[downstream_rxdat_entry_idx].dest_way} 
                                    : {dataram_rd_index,dataram_rd_way};


//data_ram rd: hit   //1:wr; 0:rd
//data_ram wr: linefill done
//linefill done write data ram and tag ram
//if(linefill_done)begin //get linefill data, write to dataram
    
    
    always_ff@(posedge clk ) begin
        if(dataram_rd_vld && dataram_rd_rdy)begin
            dataram_dout_vld     <= 1'b1            ;
            dataram_rd_txnid_out <= dataram_rd_txnid;
        end
        else begin
            dataram_dout_vld     <= 1'b0            ;
            dataram_rd_txnid_out <= 'b0             ;
        end
    end

    always_ff@(posedge clk ) begin
        if(linefill_done)begin
            linefill_done_txnid <= downstream_rxdat_pld.downstream_rxdat_txnid;
        end
    end





    //256bit  cacheline [255:0]
    toy_mem_model_bit #(
        .ADDR_WIDTH(ICACHE_INDEX_WIDTH+1  ),
        .DATA_WIDTH(ICACHE_DATA_WIDTH/2                   )
    )u_icache_data_array0 (
        .clk        (clk                  ),
        .en         (mem_en               ),    
        .wr_en      (data_array_wr_en     ),
        .addr       (data_array_addr      ),
        .rd_data    (data_array0_dout     ),
        .wr_data    (data_array0_din      )
    );

    //256bit cacheline[511:256]
    toy_mem_model_bit #(
        .ADDR_WIDTH(ICACHE_INDEX_WIDTH+1  ),
        .DATA_WIDTH(ICACHE_DATA_WIDTH/2                   )
    ) u_icache_data_array1 (
        .clk        (clk                  ),
        .en         (mem_en               ),    
        .wr_en      (data_array_wr_en     ),
        .addr       (data_array_addr      ),
        .rd_data    (data_array1_dout     ),
        .wr_data    (data_array1_din      )
    );


    always_comb begin
        upstream_txdat_data         = 'b0                                       ;
        upstream_txdat_vld          = 1'b0                                      ;
        upstream_txdat_txnid        = 'b0                                       ;
        if(dataram_dout_vld)begin
            upstream_txdat_data     = {data_array1_dout, data_array0_dout}      ;
            upstream_txdat_vld      = 1'b1                                      ;
            upstream_txdat_txnid    = dataram_rd_txnid_out                      ;
        end
        else if(linefill_data_vld) begin
            upstream_txdat_data     = linefill_data                             ;
            upstream_txdat_vld      = 1'b1                                      ;
            upstream_txdat_txnid    = linefill_done_txnid                       ;
        end
    end


endmodule
