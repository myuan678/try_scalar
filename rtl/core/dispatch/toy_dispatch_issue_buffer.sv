module toy_dispatch_issue_buffer 
    import toy_pack::*;
#(
    parameter   int unsigned OOO_DEPTH    = 4                     ,
    parameter   int unsigned S_CHANNEL    = 8                     ,
    parameter   int unsigned BUFFER_DEPTH = 16                    
)
(
    input  logic                                clk                             ,
    input  logic                                rst_n                           ,

    input  logic [S_CHANNEL-1       :0]         v_s_vld                         ,
    output logic [S_CHANNEL-1       :0]         v_s_rdy                         ,
    input  decode_pkg                           v_s_pld [S_CHANNEL-1    :0]     ,

    output logic [OOO_DEPTH-1       :0]         v_m_vld                         ,
    input  logic [OOO_DEPTH-1       :0]         v_m_rdy                         ,
    output decode_pkg                           v_m_pld [OOO_DEPTH-1  :0]       ,

    input logic                                 cancel_edge_en                       
);
    
    //==============================
    // parameter
    //==============================
    localparam DEPTH_WIDTH          = $clog2(BUFFER_DEPTH)                       ;
    localparam S_CH_DEPTH_WIDTH     = $clog2(S_CHANNEL)                          ;
    localparam OOO_DEPTH_WIDTH      = $clog2(OOO_DEPTH)                          ;
    localparam OOO_DEPTH_WIDTH_MUL2 = $clog2(OOO_DEPTH*2)                        ;

    //============================== 
    // logic
    //==============================
    genvar i;
    //==============================
    // logic 
    //==============================
    logic [OOO_DEPTH-1              :0] v_m_ld                          ;
    logic [BUFFER_DEPTH-1           :0] v_ld_en                         ;
    logic [BUFFER_DEPTH-1           :0] v_free_idx_oh  [OOO_DEPTH-1 :0] ;
    logic [DEPTH_WIDTH-1            :0] v_free_idx_bin [OOO_DEPTH-1 :0] ;
    logic [BUFFER_DEPTH-1           :0] v_mem_en                        ;
    logic [DEPTH_WIDTH              :0] wr_ptr_nxt                      ;
    logic [DEPTH_WIDTH              :0] wr_ptr_new                      ;
    logic [DEPTH_WIDTH              :0] wr_ptr                          ;
    logic [DEPTH_WIDTH              :0] ready_num                       ;
    logic [DEPTH_WIDTH              :0] cnt_o        [OOO_DEPTH-1   :0] ;  
    logic [DEPTH_WIDTH              :0] cnt_i        [S_CHANNEL-1   :0] ;
    decode_pkg                          v_mem_pld    [BUFFER_DEPTH-1:0] ;
    logic [OOO_DEPTH-1              :0] v_csr_mask      [OOO_DEPTH-1:0] ;
    logic [OOO_DEPTH-1              :0] v_m_en                          ;
    logic [S_CHANNEL-1              :0] v_s_en                          ;



    assign v_m_en = v_m_vld & v_m_rdy;
    assign v_s_en = v_s_vld & v_s_rdy;
    assign v_m_pld = v_mem_pld[OOO_DEPTH-1  :0];
    assign v_m_vld = v_mem_en[OOO_DEPTH-1  :0] & v_csr_mask[OOO_DEPTH-1];

    assign cnt_o[0] = (v_m_vld[0]&v_m_rdy[0]) ? 'd1 : 'd0;
    assign cnt_i[0] = (v_s_vld[0]&v_s_rdy[0]) ? 'd1 : 'd0;
    assign v_csr_mask[0] = v_mem_pld[0].goto_csr ? 'd1:{{(OOO_DEPTH){1'b1}}};
    
    generate
        for(i=1;i<S_CHANNEL;i=i+1)begin
            always_comb begin
                if(v_s_vld[i]&v_s_rdy[i])begin
                    cnt_i[i] = cnt_i[i-1]+1;
                end
                else begin
                    cnt_i[i] = cnt_i[i-1];
                end
            end
        end

        for(i=1;i<OOO_DEPTH;i=i+1)begin
            always_comb begin
                if(v_m_vld[i]&v_m_rdy[i])begin
                    cnt_o[i] = cnt_o[i-1]+1;
                end
                else begin
                    cnt_o[i] = cnt_o[i-1];
                end
            end
            always_comb begin
                if(v_mem_pld[i].goto_csr)begin
                    v_csr_mask[i] = v_csr_mask[i-1] & {{(OOO_DEPTH-i){1'b0}},{i{1'b1}}};
                end
                else begin
                    v_csr_mask[i] = v_csr_mask[i-1];
                end
            end
        end

    endgenerate
    assign wr_ptr_new = wr_ptr - cnt_o[OOO_DEPTH-1];
    assign wr_ptr_nxt = wr_ptr - cnt_o[OOO_DEPTH-1] + cnt_i[S_CHANNEL-1];
    assign ready_num  = BUFFER_DEPTH - wr_ptr + cnt_o[OOO_DEPTH-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            wr_ptr <= 0;
        end
        else if(cancel_edge_en)begin
            wr_ptr <= 0;
        end
        else if((|v_m_en) || (|v_s_en))begin
            wr_ptr <= wr_ptr_nxt;
        end
    end



    assign v_m_ld = ~(v_m_vld & v_m_rdy);

    assign v_ld_en = {v_mem_en[BUFFER_DEPTH-1:OOO_DEPTH],v_m_ld};

    cmn_list_lead_one #(
        .ENTRY_NUM      (BUFFER_DEPTH           ),
        .REQ_NUM        (OOO_DEPTH              )
    )u_ld_data(
        .v_entry_vld    (v_ld_en                ),
        .v_free_idx_oh  (v_free_idx_oh          ),
        .v_free_idx_bin (v_free_idx_bin         ),
        .v_free_vld     (                       )
    );


    generate

        for(i=0;i<S_CHANNEL;i=i+1)begin
            // always_comb begin 
            //     if(i<ready_num)begin
            //         v_s_rdy[i] = 1'b1;
            //     end
            //     else begin
            //         v_s_rdy[i] = 1'b0;
            //     end
            // end
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_s_rdy[i] <= 1'b1;
                end
                else if(cancel_edge_en)begin
                    v_s_rdy[i] <= 1'b1;
                end
                else if((i+8)<ready_num)begin
                    v_s_rdy[i] <= 1'b1;
                end
                else begin
                    v_s_rdy[i] <= 1'b0;
                end                
            end
        end

        for(i=0;i<BUFFER_DEPTH;i=i+1)begin
            if(i<OOO_DEPTH)begin
                always_ff @(posedge clk or negedge rst_n) begin
                    if(~rst_n)begin
                        v_mem_pld[i] <= {$bits(decode_pkg){1'b0}};
                    end
                    else if(i<wr_ptr_new)begin
                            if(v_free_idx_bin[i]<OOO_DEPTH)begin
                                v_mem_pld[i] <= v_m_pld[v_free_idx_bin[i]];
                            end
                            else begin
                                v_mem_pld[i] <= v_mem_pld[v_free_idx_bin[i]];
                            end
                    end
                    else if(i<wr_ptr_nxt)begin
                        v_mem_pld[i] <= v_s_pld[S_CH_DEPTH_WIDTH'(i-wr_ptr_new)];
                    end
                end
            end
            else begin
                always_ff @(posedge clk or negedge rst_n) begin
                    if(~rst_n)begin
                        v_mem_pld[i] <= {$bits(decode_pkg){1'b0}};
                    end
                    else if(i<wr_ptr_new)begin
                        v_mem_pld[i] <= v_mem_pld[DEPTH_WIDTH'(i+cnt_o[OOO_DEPTH-1])];
                    end
                    else if(i<wr_ptr_nxt)begin
                        v_mem_pld[i] <= v_s_pld[S_CH_DEPTH_WIDTH'(i-wr_ptr_new)];
                    end
                end     
            end
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    v_mem_en[i] <= 1'b0;
                end
                else if(cancel_edge_en)begin
                    v_mem_en[i] <= 1'b0;
                end
                else if(i<wr_ptr_nxt)begin
                    v_mem_en[i] <= 1'b1;
                end
                else begin
                    v_mem_en[i] <= 1'b0;
                end
            end
        end

    endgenerate











endmodule