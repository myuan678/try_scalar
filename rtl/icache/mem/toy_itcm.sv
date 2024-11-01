module toy_itcm
    import toy_pack::*;
    (
     input   logic                             clk,
     input   logic                             rst_n,
     output  logic                             fetch_mem_ack_vld       ,
     input   logic                             fetch_mem_ack_rdy       ,
     output  logic [FETCH_DATA_WIDTH-1:0]      fetch_mem_ack_data      ,
     output  logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:0]    fetch_mem_ack_entry_id,
     input   logic [ADDR_WIDTH-1:0]            fetch_mem_req_addr      ,
     input   logic                             fetch_mem_req_vld       ,
     output  logic                             fetch_mem_req_rdy       ,
     input   logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH-1:0]    fetch_mem_req_entry_id
    );

    localparam ITCM_DELAY = 1;

    logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:0] fetch_req_pld;
    // logic [ROB_ENTRY_ID_WIDTH:0] fetch_ack_pld;

    logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:0] fetch_ack_pld_sx [ITCM_DELAY-1:0];
    logic [FETCH_DATA_WIDTH-1:0] fetch_ack_data_sx [ITCM_DELAY-1:0];

    logic [ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:0] fetch_ack_pld_s0;
    logic [FETCH_DATA_WIDTH-1:0] fetch_ack_data_s0;
    logic fetch_mem_ack_vld_pre;
    
    assign fetch_req_pld          = {fetch_mem_req_entry_id, fetch_mem_req_vld};
    assign fetch_mem_ack_vld_pre  = fetch_ack_pld_sx[ITCM_DELAY-1][0];
    //try to add dataram rdy
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)  fetch_mem_ack_vld <= 1'b0;
        else if(fetch_mem_req_rdy && fetch_mem_ack_vld_pre) fetch_mem_ack_vld <=1'b1;
        else if(fetch_mem_ack_rdy) fetch_mem_ack_vld <= 1'b0;
    end
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            fetch_mem_ack_data <= {FETCH_DATA_WIDTH{1'b0}};
            fetch_mem_ack_entry_id <= {ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH{1'b0}};
        end
        else if (fetch_mem_ack_vld_pre && fetch_mem_req_rdy)begin
            fetch_mem_ack_entry_id <= fetch_ack_pld_sx[ITCM_DELAY-1][ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:1];
            fetch_mem_ack_data     <= fetch_ack_data_sx[ITCM_DELAY-1];
        end
    end

   
    //assign fetch_mem_ack_entry_id = fetch_ack_pld_sx[ITCM_DELAY-1][ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:1]; //opcode+entry_index+txnid
    //assign fetch_mem_ack_data     = fetch_ack_data_sx[ITCM_DELAY-1];
    //always_ff@(posedge clk )begin
    //    fetch_mem_ack_entry_id <= fetch_ack_pld_sx[ITCM_DELAY-1][ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH:1];
    //    fetch_mem_ack_data     <= fetch_ack_data_sx[ITCM_DELAY-1];
    //end
    assign fetch_mem_req_rdy   = 1'b1;

    generate
        for(genvar i=0; i < ITCM_DELAY; i=i+1) begin: GEN_DELAY
            if (i==0) begin 
                always_ff @(posedge clk or negedge rst_n) begin 
                    if (~rst_n) begin
                        fetch_ack_pld_sx[i]  <= {(ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH+1){1'b0}};
                        fetch_ack_data_sx[i] <= {FETCH_DATA_WIDTH{1'b0}};
                    end else begin 
                        fetch_ack_pld_sx[i]  <= fetch_ack_pld_s0 ;
                        fetch_ack_data_sx[i] <= fetch_ack_data_s0;
                    end
                end
            end else begin
                always_ff @(posedge clk or negedge rst_n) begin 
                    if (~rst_n) begin
                        fetch_ack_pld_sx[i]  <= {(ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH+1){1'b0}};
                        fetch_ack_data_sx[i] <= {FETCH_DATA_WIDTH{1'b0}};
                    end else begin 
                        fetch_ack_pld_sx[i]  <= fetch_ack_pld_sx[i-1];
                        fetch_ack_data_sx[i] <= fetch_ack_data_sx[i-1];
                    end
                end
            end
        end
    endgenerate

    toy_imem_model #(
                     .ARGPARSE_KEY  ("HEX"               ),  
                     .ADDR_WIDTH    (ADDR_WIDTH          ),
                     .DATA_WIDTH    (FETCH_DATA_WIDTH    ),
                     .FETCH_SB_WIDTH(ICACHE_REQ_OPCODE_WIDTH+MSHR_ENTRY_INDEX_WIDTH+ROB_ENTRY_ID_WIDTH+1),
                     .OFFSET_WIDTH  (BPU_OFFSET_WIDTH+1  )
                    ) u_imem (
                              .clk          (clk                                       ),
                              .addr         ({9'b0, fetch_mem_req_addr[ADDR_WIDTH-9:1]}),
                              .en           (fetch_mem_req_vld                         ),
                              .wr_en        (1'b0                                      ),
                              .wr_data      ({FETCH_DATA_WIDTH{1'b0}}                  ),
                              .rd_data      (fetch_ack_data_s0                         ),
                              .req_send_back(fetch_req_pld                             ),
                              .ack_send_back(fetch_ack_pld_s0                          )
                             );


endmodule