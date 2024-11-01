module hazard_check 
    import toy_pack::*;
    #(
    parameter integer unsigned    MSHR_ENTRY_NUM=8, 
    parameter integer unsigned    MSHR_ENTRY_INDEX_WIDTH=4, 
    parameter type    PLD_TYPE = logic
    )
    (
    input  logic                                clk,
    input  logic                                rst_n,
    input  mshr_entry_t                         v_mshr_entry_array[MSHR_ENTRY_NUM-1:0],
    input  pc_req_t                             req_pld,
    input  logic                                lru_pick,
    input  logic                                alloc_vld,
    input  logic [MSHR_ENTRY_INDEX_WIDTH-1:0]   alloc_index,
    input  logic [MSHR_ENTRY_INDEX_WIDTH:0]     entry_release_done_index,
    input  logic [MSHR_ENTRY_NUM-1:0]           v_linefill_done,
    input  logic [MSHR_ENTRY_NUM-1:0]           v_hit_entry_done,
    output logic [MSHR_ENTRY_NUM-1:0]           v_index_way_bitmap[MSHR_ENTRY_NUM-1:0]
    );

    //logic [MSHR_ENTRY_NUM-1:0]  v_index_way_bitmap_pre[MSHR_ENTRY_NUM-1:0];
    //generate
    //    for (genvar i = 0; i < MSHR_ENTRY_NUM; i++)begin
    //        always_ff@(posedge clk or negedge rst_n) begin
    //            if(!rst_n)begin
    //                v_index_way_bitmap_pre[0][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[1][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[2][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[3][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[4][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[5][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[6][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[7][i] <= 1'b0;
    //            end
    //            else if(pre_tag_req_vld)begin
    //                if((v_mshr_entry_array[i].valid==1'b1) && (v_mshr_entry_array[i].req_pld.addr.index==req_pld.addr.index) )begin
    //                    v_index_way_bitmap_pre[alloc_index][i] <= 1'b1;
    //                end
    //            end
    //            else begin
    //                v_index_way_bitmap_pre[0][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[1][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[2][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[3][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[4][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[5][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[6][i] <= 1'b0; 
    //                v_index_way_bitmap_pre[7][i] <= 1'b0;
    //            end
    //        end
    //    end
    //endgenerate

    //generate
    //    for(genvar i = 0; i < MSHR_ENTRY_NUM; i++)begin
    //        always_comb begin
    //            pre_check_pass = 1'b0;
    //            v_index_way_bitmap[0][i] = 0;
    //            v_index_way_bitmap[1][i] = 0;
    //            v_index_way_bitmap[2][i] = 0;
    //            v_index_way_bitmap[3][i] = 0;
    //            v_index_way_bitmap[4][i] = 0;
    //            v_index_way_bitmap[5][i] = 0;
    //            v_index_way_bitmap[6][i] = 0;
    //            v_index_way_bitmap[7][i] = 0;
    //            if(alloc_vld)begin
    //                if(v_mshr_entry_array[i].dest_way==lru_pick)begin
    //                    pre_check_pass = 1'b0;
    //                    v_index_way_bitmap[alloc_index][i] = v_index_way_bitmap_pre[alloc_index][i];
    //                end
    //                else begin
    //                    pre_check_pass = 1'b1;
    //                    v_index_way_bitmap[alloc_index][i] = 1'b0;
    //                end
    //            end
    //        end
    //    end
    //endgenerate




    generate 
        for (genvar i = 0; i < MSHR_ENTRY_NUM; i++)begin
            always_comb begin
                v_index_way_bitmap[0][i] = 1'b0; 
                v_index_way_bitmap[1][i] = 1'b0; 
                v_index_way_bitmap[2][i] = 1'b0; 
                v_index_way_bitmap[3][i] = 1'b0; 
                v_index_way_bitmap[4][i] = 1'b0; 
                v_index_way_bitmap[5][i] = 1'b0; 
                v_index_way_bitmap[6][i] = 1'b0; 
                v_index_way_bitmap[7][i] = 1'b0; 
                if(alloc_vld)begin
                    if((i==alloc_index) | (i==entry_release_done_index))begin
                        v_index_way_bitmap[alloc_index][i] = 1'b0; 
                    end
                    else if((v_mshr_entry_array[i].valid==1'b1) && (v_mshr_entry_array[i].req_pld.addr.index==req_pld.addr.index) && (v_mshr_entry_array[i].dest_way==lru_pick))begin
                        v_index_way_bitmap[alloc_index][i] = 1'b1; 
                    end
                end
            end
        end
    endgenerate

    


endmodule