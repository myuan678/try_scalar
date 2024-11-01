
package toy_pack;

  localparam integer unsigned ADDR_WIDTH                   = 32;
  localparam integer unsigned ICACHE_SIZE                  = 32768;   //32KByte
  localparam integer unsigned ICACHE_LINE_SIZE             = 32;      //64Byte
  localparam integer unsigned WAY_NUM                      = 2 ;

  localparam integer unsigned ICACHE_SET_NUM               = ICACHE_SIZE/(ICACHE_LINE_SIZE * WAY_NUM);

  localparam integer unsigned ICACHE_INDEX_WIDTH           = $clog2(ICACHE_SET_NUM) ;
  localparam integer unsigned ICACHE_OFFSET_WIDTH          = $clog2(ICACHE_LINE_SIZE) ;
  localparam integer unsigned ICACHE_TAG_WIDTH             = ADDR_WIDTH-ICACHE_INDEX_WIDTH-ICACHE_OFFSET_WIDTH;
  localparam integer unsigned ICACHE_REQ_OPCODE_WIDTH      = 5 ;
  localparam integer unsigned ICACHE_REQ_TXNID_WIDTH       = 5 ;
  //localparam integer unsigned ADDR_WIDTH = ICACHE_TAG_WIDTH + ICACHE_INDEX_WIDTH + ICACHE_OFFSET_WIDTH;
  
  
  localparam integer unsigned MSHR_ENTRY_NUM               = 16      ;
  localparam integer unsigned MSHR_ENTRY_INDEX_WIDTH       = $clog2(MSHR_ENTRY_NUM);
  localparam integer unsigned ICACHE_UPSTREAM_DATA_WIDTH   = ICACHE_LINE_SIZE*8   ;
  localparam integer unsigned ICACHE_DOWNSTREAM_DATA_WIDTH = ICACHE_LINE_SIZE*8    ;
  localparam integer unsigned DOWNSTREAM_OPCODE            = 5'd1   ;
  localparam integer unsigned UPSTREAM_OPCODE              = 5'd2   ;
  localparam integer unsigned PREFETCH_OPCODE              = 5'd3   ;
  localparam integer unsigned ICACHE_DATA_WIDTH            = ICACHE_LINE_SIZE*8     ;  //cache line size 256bit
  localparam integer unsigned ICACHE_TAG_RAM_WIDTH         = ICACHE_TAG_WIDTH*WAY_NUM + 2;
  //localparam integer unsigned PRE_ALLO_NUM                 = 4;
  
  
  typedef struct packed{
    logic [ICACHE_TAG_WIDTH-1            :0]           tag                        ;
    logic [ICACHE_INDEX_WIDTH-1          :0]           index                      ;
    logic [ICACHE_OFFSET_WIDTH-1         :0]           offset                     ;
    } req_addr_t;
  
  typedef struct packed{
    req_addr_t                                         addr                       ;
    logic [ICACHE_REQ_OPCODE_WIDTH-1     :0]           opcode                     ;
    logic [ICACHE_REQ_TXNID_WIDTH-1      :0]           txnid                      ;
  } pc_req_t;
  
  
  typedef struct packed{
    logic [ICACHE_REQ_OPCODE_WIDTH-1     :0]           downstream_txreq_opcode    ;
    logic [ICACHE_REQ_TXNID_WIDTH-1      :0]           downstream_txreq_txnid     ;
    req_addr_t                                         downstream_txreq_addr      ;
    } downstream_txreq_t;
  
  typedef struct packed{
    logic [ICACHE_REQ_OPCODE_WIDTH-1     :0]           downstream_rxdat_opcode    ;
    logic [ICACHE_REQ_TXNID_WIDTH-1      :0]           downstream_rxdat_txnid     ;
    logic [ICACHE_DOWNSTREAM_DATA_WIDTH-1:0]           downstream_rxdat_data      ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1      :0]           downstream_rxdat_entry_idx ;
  } downstream_rxdat_t;
  
  typedef struct packed{
      logic                                            valid                      ;
      pc_req_t                                         req_pld                    ;
      logic                                            dest_way                   ;
      //logic [MSHR_ENTRY_NUM-1             :0]          hit_bitmap                 ;
      logic [MSHR_ENTRY_NUM-1             :0]          index_way_bitmap           ;
      logic release_en;
      logic hit;
      logic miss;
  } mshr_entry_t;
  
  
  typedef struct packed{
      pc_req_t                                         pld                        ;
      logic                                            dest_way                   ;
  } entry_data_t;

  typedef struct packed {
    pc_req_t  buf_pld;
    logic     dest_way;
  } wr_tag_buf_pld_t;

  typedef struct packed {
    logic                                   dataram_rd_way;
    logic [ICACHE_INDEX_WIDTH-1    :0]      dataram_rd_index;
    logic [ICACHE_REQ_TXNID_WIDTH-1:0]      dataram_rd_txnid;
  } dataram_rd_pld_t;



endpackage