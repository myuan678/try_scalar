module icache_prefetch_engine
    import toy_pack::*;
(
    input  logic                                clk,
    input  logic                                rst_n,

    input  logic                                miss_for_prefetch,
    input  req_addr_t                           miss_addr_for_prefetch,
    input  logic [ICACHE_REQ_TXNID_WIDTH-1:0]   miss_txnid_for_prefetch,
    output logic                                pref_to_mshr_req_rdy,

    output logic                                prefetch_req_vld,
    output pc_req_t                             prefetch_req_pld,
    input  logic                                prefetch_req_rdy
);

    pc_req_t                                    buffer[MSHR_ENTRY_NUM-1:0];
    logic [MSHR_ENTRY_INDEX_WIDTH:0]            write_ptr;
    logic [MSHR_ENTRY_INDEX_WIDTH:0]            read_ptr;
    logic                                       empty;
    logic                                       full;
    pc_req_t                                    prefetch_pld;

    assign prefetch_pld.addr   = miss_addr_for_prefetch + 'h40;
    assign prefetch_pld.txnid  = miss_txnid_for_prefetch;
    assign prefetch_pld.opcode = PREFETCH_OPCODE;

    assign empty = (write_ptr == read_ptr);
    assign full  = ((write_ptr[MSHR_ENTRY_INDEX_WIDTH-1:0] == read_ptr[MSHR_ENTRY_INDEX_WIDTH-1:0]) &&
                    (write_ptr[MSHR_ENTRY_INDEX_WIDTH] != read_ptr[MSHR_ENTRY_INDEX_WIDTH]));

    assign pref_to_mshr_req_rdy = 1'b1; // Always ready to accept mshr input
    assign prefetch_req_vld = !empty;
    assign prefetch_req_pld = buffer[read_ptr[MSHR_ENTRY_INDEX_WIDTH-1:0]];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= '0;
            read_ptr  <= '0;
            for (int i = 0; i < MSHR_ENTRY_NUM; i++) begin
                buffer[i] <= '0;
            end
        end
        else begin
            if (miss_for_prefetch) begin
                buffer[write_ptr[MSHR_ENTRY_INDEX_WIDTH-1:0]] <= prefetch_pld;
                write_ptr <= write_ptr + 1;
                if (full) begin
                    read_ptr <= read_ptr + 1;
                end
            end
            else begin
                write_ptr <= write_ptr;
            end

            if (prefetch_req_vld && prefetch_req_rdy) begin
                read_ptr <= read_ptr + 1;
            end
            else begin
                read_ptr <= read_ptr;
            end
        end
    end

endmodule














//module icache_prefetch_engine 
//	import toy_pack::*;
//	#(
//    parameter integer unsigned FIFO_DEPTH = 8  
//	) 
//	(
//    input logic 								clk						,
//    input logic 								rst_n					,
//    
//    input  logic 								miss_for_prefetch		,
//    input  req_addr_t	 						miss_addr_for_prefetch	,
//    input  logic [ICACHE_REQ_TXNID_WIDTH-1:0]	miss_txnid_for_prefetch	,
//    output logic 								pref_to_mshr_req_rdy	,
//    
//    output  logic  								prefetch_req_vld		,
//    output  pc_req_t 							prefetch_req_pld		,
//    input   logic  								prefetch_req_rdy	
//);
//
//    pc_req_t 						  prefetch_pld			;
//    logic                           fifo_wr_en;
//    logic                           fifo_rd_en;
//    logic                           fifo_empty;
//    logic                           fifo_full;
//    req_addr_t                      fifo_wr_data;
//    req_addr_t                      fifo_rd_data;
//
//    assign prefetch_pld.addr    = miss_addr_for_prefetch	;
//    assign prefetch_pld.txnid   = miss_txnid_for_prefetch	;
//    assign prefetch_pld.opcode  = 1							;
//
//
//    sync_fifo #(
//        .FIFO_WIDTH     ($bits(pc_req_t)),
//        //.FIFO_WIDTH_BIT (              ),
//        .FIFO_DEPTH     (MSHR_ENTRY_NUM ), 
//        .FIFO_DEPTH_BIT (MSHR_ENTRY_INDEX_WIDTH)
//    ) u_sync_fifo (
//        .clk            (clk            ),
//        .rst_n          (rst_n          ),
//        .w_en           (fifo_wr_en     ),
//        .data_write     (fifo_wr_data   ),
//        .r_en           (fifo_rd_en     ),
//        .data_read      (fifo_rd_data   ),
//        .flag_empty     (fifo_empty     ),
//        .flag_full      (fifo_full      )
//    );
//
//    assign pref_to_mshr_req_rdy = !fifo_full;
//    assign fifo_wr_en = miss_for_prefetch && !fifo_full;
//    assign fifo_wr_data = prefetch_pld;
//
//    //assign prefetch_req_vld = !fifo_empty;
//    assign prefetch_req_pld = fifo_rd_data;
//    //assign fifo_rd_en = prefetch_req_vld && prefetch_req_rdy ;
//    assign fifo_rd_en = !fifo_empty;
//
//    always_ff @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            prefetch_req_vld <= 1'b0;
//        end
//        else if(fifo_empty== 1'b0)begin
//            prefetch_req_vld <= 1'b1;
//        end
//        /////////
//        else if(prefetch_req_rdy == 1'b1 && prefetch_req_vld == 1'b1) begin
//            prefetch_req_vld <= 1'b0;
//        end
//        ///////////
//        else begin
//            prefetch_req_vld <= 1'b0;
//        end
//    end
//
//endmodule