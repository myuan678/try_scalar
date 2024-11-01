module icache_memory_adapter
    import toy_pack::*;
(
    input  logic                                    clk,
    input  logic                                    rst_n,

    // ICache downstream interface
    input  logic                                    downstream_txreq_vld,
    output logic                                    downstream_txreq_rdy,
    input  pc_req_t                                 downstream_txreq_pld,
    input  logic [MSHR_ENTRY_INDEX_WIDTH-1:0]       downstream_txreq_entry_id,
    
    output logic                                    downstream_rxdat_vld,
    input  logic                                    downstream_rxdat_rdy,
    output downstream_rxdat_t                       downstream_rxdat_pld,

    // Memory model interface
    output logic                                    adapter_fetch_mem_req_vld,
    input  logic                                    adapter_fetch_mem_req_rdy,
    output logic [ADDR_WIDTH-1:0]                   adapter_fetch_mem_req_addr,
    output logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:0]           adapter_fetch_mem_req_entry_id,
    
    input  logic                                    adapter_fetch_mem_ack_vld,
    output logic                                    adapter_fetch_mem_ack_rdy,
    input  logic [FETCH_DATA_WIDTH-1:0]             adapter_fetch_mem_ack_data,
    input  logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:0]           adapter_fetch_mem_ack_entry_id
);

    // Request path连接
    // 将icache的request信号连接到memory model
    assign adapter_fetch_mem_req_vld                                             = downstream_txreq_vld;
    assign downstream_txreq_rdy                                          = adapter_fetch_mem_req_rdy;
    assign adapter_fetch_mem_req_addr[ADDR_WIDTH-1:0]                            = downstream_txreq_pld.addr; 

    assign adapter_fetch_mem_req_entry_id[ROB_ENTRY_ID_WIDTH-1:0]                = downstream_txreq_pld.txnid;
    assign adapter_fetch_mem_req_entry_id[MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:ROB_ENTRY_ID_WIDTH]= downstream_txreq_entry_id;
    assign adapter_fetch_mem_req_entry_id[ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH :MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH] = downstream_txreq_pld.opcode;
    // Response path连接
    // 将memory model的响应数据连接回icache
    assign downstream_rxdat_vld                            = adapter_fetch_mem_ack_vld;
    assign adapter_fetch_mem_ack_rdy                       = downstream_rxdat_rdy;
    assign downstream_rxdat_pld.downstream_rxdat_data      = adapter_fetch_mem_ack_data;  // rxdat_t中data
    assign downstream_rxdat_pld.downstream_rxdat_entry_idx = adapter_fetch_mem_ack_entry_id[MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:ROB_ENTRY_ID_WIDTH]; 
    assign downstream_rxdat_pld.downstream_rxdat_txnid     = adapter_fetch_mem_ack_entry_id[ROB_ENTRY_ID_WIDTH-1:0];
    assign downstream_rxdat_pld.downstream_rxdat_opcode    = adapter_fetch_mem_ack_entry_id[ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1: MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH];

endmodule