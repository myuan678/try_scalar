`define INST_FIELD_OPEXT    [1 : 0]
`define INST_FIELD_OPCODE   [6 : 2]
`define INST_FIELD_RD       [11: 7]
`define INST_FIELD_FUNCT3   [14:12]
`define INST_FIELD_RS1      [19:15]
`define INST_FIELD_RS2      [24:20]
`define INST_FIELD_RS3      [31:27]
`define INST_FIELD_FUNCT5   [31:27]
`define INST_FIELD_FUNCT7   [31:25]
`define INST_FIELD_FUNCT12  [31:20]
`define INST_FILED_U_IMM    [31:20]
`define INST_FILED_F_RM     [14:12]

`define NEW_PRED_T          3'b100
`define NEW_PRED_NT         3'b011
`define NEW_U               2'b0


package toy_pack;

    localparam integer unsigned ADDR_WIDTH          = 32;
    localparam integer unsigned DATA_WIDTH          = 256;
    localparam integer unsigned REG_WIDTH           = 32;
    localparam integer unsigned FETCH_SB_WIDTH      = 10;

    localparam integer unsigned INST_WIDTH_32          = 32;
    localparam integer unsigned BUS_DATA_WIDTH         = 256;
    localparam integer unsigned FETCH_WRITE_CHANNEL    = 8;
    localparam integer unsigned FETCH_DATA_WIDTH       = INST_WIDTH_32*FETCH_WRITE_CHANNEL;
    localparam integer unsigned INST_NUM_WIDTH         = $clog2(2*FETCH_WRITE_CHANNEL)+1;
    localparam integer unsigned INST_READ_CHANNEL      = 8;
    localparam integer unsigned INST_DECODE_NUM        = 4;
    localparam integer unsigned INST_ALU_NUM           = 4;
    localparam integer unsigned EU_NUM                 = 10; // 3-lsu , 4-alu ,float/csr/mext
    localparam integer unsigned ARCH_ENTRY_NUM         = 32;
    localparam integer unsigned PHY_REG_NUM            = 64;
    localparam integer unsigned PHY_REG_ID_WIDTH       = $clog2(PHY_REG_NUM);
    localparam integer unsigned LSU_DEPTH              = 16;
    localparam integer unsigned STU_DEPTH              = 32;
    localparam integer unsigned LDU_DEPTH              = 32;
    localparam integer unsigned STU_CHANNEL            = 2;
    localparam integer unsigned LDU_CHANNEL            = 2;
    localparam integer unsigned COMMIT_CHANNEL         = 4;
    localparam integer unsigned COMMIT_QUEUE_DEPTH     = 64;
    localparam integer unsigned INST_WIDTH             = INST_WIDTH_32;
    localparam integer unsigned INST_IDX_WIDTH         = $clog2(COMMIT_QUEUE_DEPTH);
    localparam integer unsigned COMMIT_REL_CHANNEL     = COMMIT_CHANNEL;
    localparam integer unsigned FETCH_QUEUE_DEPTH      = 32;
    localparam integer unsigned MEXT_STAGES            = 3; // real is mext_stages - 1
    localparam integer unsigned FP_STAGES              = 6; // real is fp_stages - 1

    // branch prediction
    localparam integer unsigned GHR_LENGTH            = 131;
    localparam integer unsigned PRED_BLOCK_LEN        = FETCH_WRITE_CHANNEL;
    localparam integer unsigned BPU_OFFSET_WIDTH      = $clog2(PRED_BLOCK_LEN);
    localparam integer unsigned BP0_ENTRY_NUM         = 64;
    localparam integer unsigned BP0_TAG_WIDTH         = 16;
    localparam integer unsigned TAGE_TABLE_NUM        = 4;      // t0~3 exclude base
    localparam integer unsigned TAGE_BASE_DEPTH       = 8192;
    localparam integer unsigned TAGE_BASE_PRED_WIDTH  = 2;
    localparam integer unsigned TAGE_BASE_INDEX_WIDTH = $clog2(TAGE_BASE_DEPTH);
    localparam integer unsigned TAGE_T0_DEPTH         = 1024;
    localparam integer unsigned TAGE_T1_DEPTH         = 1024;
    localparam integer unsigned TAGE_T2_DEPTH         = 1024;
    localparam integer unsigned TAGE_T3_DEPTH         = 1024;
    localparam integer unsigned TAGE_T0_TAG_WIDTH     = 8;
    localparam integer unsigned TAGE_T1_TAG_WIDTH     = 8;
    localparam integer unsigned TAGE_T2_TAG_WIDTH     = 8;
    localparam integer unsigned TAGE_T3_TAG_WIDTH     = 8;
    localparam integer unsigned TAGE_T0_INDEX_WIDTH   = $clog2(TAGE_T0_DEPTH);
    localparam integer unsigned TAGE_T1_INDEX_WIDTH   = $clog2(TAGE_T1_DEPTH);
    localparam integer unsigned TAGE_T2_INDEX_WIDTH   = $clog2(TAGE_T2_DEPTH);
    localparam integer unsigned TAGE_T3_INDEX_WIDTH   = $clog2(TAGE_T3_DEPTH);
    localparam integer unsigned TAGE_T0_HIST_LEN      = 10;
    localparam integer unsigned TAGE_T1_HIST_LEN      = 20;
    localparam integer unsigned TAGE_T2_HIST_LEN      = 30;
    localparam integer unsigned TAGE_T3_HIST_LEN      = 40;
    localparam integer unsigned TAGE_TX_DEPTH         = 1024;
    localparam integer unsigned TAGE_TX_TAG_WIDTH     = 8;
    localparam integer unsigned TAGE_TX_INDEX_WIDTH   = $clog2(TAGE_T0_DEPTH);
    localparam integer unsigned TAGE_TX_PRED_WIDTH    = 3;
    localparam integer unsigned TAGE_TX_USEFUL_WIDTH  = 2;
    localparam integer unsigned TAGE_CLR_WIDTH        = 18;
    localparam integer unsigned TAGE_CLR_CYCLE        = 2**TAGE_CLR_WIDTH - 1;
    localparam integer unsigned TAGE_USE_ALT_WIDTH    = 4;
    localparam integer unsigned TAGE_USE_ALT_MAX      = 2**TAGE_USE_ALT_WIDTH - 1;
    localparam integer unsigned BTB_WAY_NUM           = 4;
    localparam integer unsigned BTB_DEPTH             = 1024;
    localparam integer unsigned BTB_INDEX_WIDTH       = $clog2(BTB_DEPTH);
    localparam integer unsigned BTB_TAG_WIDTH         = 10;
    localparam integer unsigned ENTRY_BUFFER_NUM      = 16;
    localparam integer unsigned ENTRY_BUFFER_PTR_WIDTH= $clog2(ENTRY_BUFFER_NUM);
    localparam integer unsigned RAS_DEPTH             = 32;
    localparam integer unsigned RAS_PTR_WIDTH         = $clog2(RAS_DEPTH);

    localparam integer unsigned ROB_DEPTH             = 16;
    localparam integer unsigned ROB_ENTRY_ID_WIDTH    = $clog2(ROB_DEPTH);
    localparam integer unsigned BTFIFO_DEPTH          = 16;
    localparam integer unsigned FILTER_CHANNEL        = FETCH_WRITE_CHANNEL*2;
    localparam integer unsigned FE_COMMIT_CHANNEL     = 1;
    localparam integer unsigned COMMIT_BUFFER_DEPTH   = 8;


    // localparam integer unsigned ALIGN_WIDTH        = $clog2(FETCH_DATA_WIDTH/8/2);
    localparam integer unsigned ALIGN_WIDTH           = 5; //2: 32-bit; 3: 64-bit; 4: 128-bit ...


//=============================================================================
//icache add start
//=============================================================================
    //localparam integer unsigned ADDR_WIDTH                   = 32;
    localparam integer unsigned ICACHE_SIZE                  = 32768;   //32KByte
    localparam integer unsigned ICACHE_LINE_SIZE             = 32;      //64Byte
    localparam integer unsigned WAY_NUM                      = 2 ;
    
    localparam integer unsigned ICACHE_SET_NUM               = ICACHE_SIZE/(ICACHE_LINE_SIZE * WAY_NUM);
    
    localparam integer unsigned ICACHE_INDEX_WIDTH           = $clog2(ICACHE_SET_NUM) ;
    localparam integer unsigned ICACHE_OFFSET_WIDTH          = $clog2(ICACHE_LINE_SIZE) ;
    localparam integer unsigned ICACHE_TAG_WIDTH             = ADDR_WIDTH-ICACHE_INDEX_WIDTH-ICACHE_OFFSET_WIDTH;
    localparam integer unsigned ICACHE_REQ_OPCODE_WIDTH      = 5 ;
    localparam integer unsigned ICACHE_REQ_TXNID_WIDTH       = 4 ;
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

//=========================================================================================
//icache add end
//=========================================================================================
    // all the funct3 codes

    typedef enum logic [2:0] {
                              F3_ADDSUB = 3'b000,
                              F3_SLT    = 3'b010,
                              F3_SLTU   = 3'b011,
                              F3_XOR    = 3'b100,
                              F3_OR     = 3'b110,
                              F3_AND    = 3'b111,
                              F3_SLL    = 3'b001,
                              F3_SR     = 3'b101
                             } funct3_op_t;

    typedef enum logic [2:0] {
                              F3_BEQ  = 3'b000,
                              F3_BNE  = 3'b001,
                              F3_BLT  = 3'b100,
                              F3_BGE  = 3'b101,
                              F3_BLTU = 3'b110,
                              F3_BGEU = 3'b111
                             } funct3_branch_t;

    typedef enum logic [2:0] {
                              F3_LB  = 3'b000,
                              F3_LH  = 3'b001,
                              F3_LW  = 3'b010,
                              F3_LBU = 3'b100,
                              F3_LHU = 3'b101
                             } funct3_load_t;

    typedef enum logic [2:0] {
                              F3_SB  = 3'b000,
                              F3_SH  = 3'b001,
                              F3_SW  = 3'b010
                             } funct3_store_t;

    typedef enum logic [2:0] {
                              F3_FENCE  = 3'b000,
                              F3_FENCEI = 3'b001
                             } funct3_misc_mem_t;

    typedef enum logic [2:0] {
                              F3_CSRRW  = 3'b001,
                              F3_CSRRS  = 3'b010,
                              F3_CSRRC  = 3'b011,
                              F3_CSRRWI = 3'b101,
                              F3_CSRRSI = 3'b110,
                              F3_CSRRCI = 3'b111,
                              F3_PRIV   = 3'b000
                             } funct3_system_t;

    typedef enum logic [2:0] {
                              F3_MUL      = 3'b000,
                              F3_MULH     = 3'b001,
                              F3_MULHSU   = 3'b010,
                              F3_MULHU    = 3'b011,
                              F3_DIV      = 3'b100,
                              F3_DIVU     = 3'b101,
                              F3_REM      = 3'b110,
                              F3_REMU     = 3'b111
                             } funct3_mul_t;


    typedef enum logic {
                        TOY_BUS_READ    = 1'b0,
                        TOY_BUS_WRITE   = 1'b1
                       } toy_bus_op_t;


    typedef enum logic [11:0] {
                               F12_ECALL  = 12'b000000000000,
                               F12_EBREAK = 12'b000000000001,
                               F12_MRET   = 12'b001100000010
                              //F12_WFI    = 12'b000100000101
                              } funct12_t;





    typedef struct packed {
                           logic [31:0] instruction    ;
                           logic [31:0] pc             ;
                          } instr_t;


    // RISC-V opcodes
    typedef enum logic [4:0] {
                              OPC_LOAD        = 5'b00000,
                              OPC_LOAD_FP     = 5'b00001,
                              OPC_CUST0       = 5'b00010,
                              OPC_MISC_MEM    = 5'b00011,
                              OPC_OP_IMM      = 5'b00100,
                              OPC_AUIPC       = 5'b00101,
                              //OPC_OP_IMM_32 = 5'b00110,
                              //OPC_48B1      = 5'b00111,

                              OPC_STORE       = 5'b01000,
                              OPC_STORE_FP    = 5'b01001,
                              OPC_CUST1       = 5'b01010,
                              OPC_AMO         = 5'b01011,
                              OPC_OP          = 5'b01100,
                              OPC_LUI         = 5'b01101,
                              //OPC_OP_32     = 5'b01110,
                              //OPC_64B       = 5'b01111,

                              OPC_FMADD       = 5'b10000,
                              OPC_FMSUB       = 5'b10001,
                              OPC_FNMSUB      = 5'b10010,
                              OPC_FNMADD      = 5'b10011,
                              OPC_OP_FP       = 5'b10100,
                              //OPC_RSVD1     = 5'b10101,
                              OPC_CUST2       = 5'b10110,
                              //OPC_48B2      = 5'b10111,

                              OPC_BRANCH      = 5'b11000,
                              OPC_JALR        = 5'b11001,
                              //OPC_RSVD2     = 5'b11010,
                              OPC_JAL         = 5'b11011,
                              OPC_SYSTEM      = 5'b11100,
                              //OPC_RSVD3     = 5'b11101,
                              OPC_CUST3       = 5'b11110
                             //OPC_80B       = 5'b11111,
                             } opcode_t;


    // CSR addresses
    typedef enum logic [11:0] {
                               CSR_ADDR_CYCLE     = 12'hC00,
                               CSR_ADDR_TIME      = 12'hC01,
                               CSR_ADDR_INSTRET   = 12'hC02,
                               CSR_ADDR_CANCEL    = 12'hC03,
                               CSR_ADDR_CYCLEH    = 12'hC80,
                               CSR_ADDR_TIMEH     = 12'hC81,
                               CSR_ADDR_INSTRETH  = 12'hC82,
                               CSR_ADDR_CANCELH   = 12'hC83,

                               CSR_ADDR_MISA      = 12'hF10,
                               CSR_ADDR_MVENDORID = 12'hF11,
                               CSR_ADDR_MARCHID   = 12'hF12,
                               CSR_ADDR_MIMPID    = 12'hF13,
                               CSR_ADDR_MHARTID   = 12'hF14,

                               CSR_ADDR_MSTATUS   = 12'h300,
                               CSR_ADDR_MEDELEG   = 12'h302,
                               CSR_ADDR_MIDELEG   = 12'h303,
                               CSR_ADDR_MIE       = 12'h304,
                               CSR_ADDR_MTVEC     = 12'h305,

                               CSR_ADDR_MSCRATCH  = 12'h340,
                               CSR_ADDR_MEPC      = 12'h341,
                               CSR_ADDR_MCAUSE    = 12'h342,
                               CSR_ADDR_MTVAL     = 12'h343,
                               CSR_ADDR_MIP       = 12'h344,

                               CSR_ADDR_MCYCLE    = 12'hB00,
                               CSR_ADDR_MTIME     = 12'hB01,
                               CSR_ADDR_MCYCLEH   = 12'hB80,
                               CSR_ADDR_MINSTRET  = 12'hB02,
                               CSR_ADDR_MTIMEH    = 12'hB81,
                               CSR_ADDR_MINSTRETH = 12'hB82,

                               // float csr
                               CSR_ADDR_FFLAGS    = 12'h001,
                               CSR_ADDR_FRM       = 12'h002,
                               CSR_ADDR_FCSR      = 12'h003,

                               // non-standard but we don't want to memory-map mtimecmp
                               CSR_ADDR_MTIMECMP  = 12'h7C1,
                               CSR_ADDR_MTIMECMPH = 12'h7C2,

                               // provisional debug CSRs
                               CSR_ADDR_DCSR      = 12'h7B0,
                               CSR_ADDR_DPC       = 12'h7B1,
                               CSR_ADDR_DSCRATCH  = 12'h7B2
                              } csr_t;


    typedef struct packed {
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           // logic                               inst_nxt_pc_flag     ;
                           logic [ADDR_WIDTH-1         :0]     inst_nxt_pc          ;
                           logic                               rd_en                ;
                           logic                               fp_rd_en             ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     phy_reg_index        ;
                           logic                               stq_commit_entry_en  ;
                           logic [$clog2(STU_DEPTH)-1  :0]     stq_commit_entry     ;
                           logic [7                    :0]     FCSR_en              ;
                           logic [7                    :0]     FCSR_data            ;
                           logic [INST_WIDTH_32-1:0]           inst_val             ;  // for bpu
                           logic                               is_cext              ;  // for bpu
                           logic                               is_call              ;  // for bpu
                           logic                               is_ret               ;  // for bpu
                           logic                               is_ind               ;  // for test
                          } commit_pkg;

    typedef struct packed {
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [REG_WIDTH-1          :0]     mem_req_data         ;
                           logic                               rd_en                ;
                           logic                               fp_rd_en             ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     phy_reg_index        ;
                           logic                               c_ext                ;

                          } ldq_ack_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           logic                                    taken  ;
                           logic [ADDR_WIDTH-1:0]                   tgt_pc ;
                           logic [BPU_OFFSET_WIDTH-1:0]             offset ;
                           logic                                    is_cext;
                           logic                                    carry;
                           logic                                    need_align;
                          } bpu_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           logic                                    taken  ;
                           logic                                    taken_err;
                           logic [ADDR_WIDTH-1:0]                   tgt_pc ;
                           logic [BPU_OFFSET_WIDTH-1:0]             offset ;
                           logic                                    is_cext;
                           logic                                    carry;
                          } bpu_update_pkg;


    typedef struct packed {
                           logic [BP0_TAG_WIDTH-1:0]                tag   ;
                           logic [BPU_OFFSET_WIDTH-1:0]             offset;
                           logic                                    is_cext;
                           logic                                    carry;
                           logic [ADDR_WIDTH-1:0]                   tgt_pc;
                          } l0btb_entry_pkg;


    typedef struct packed {
                           logic                                    valid;
                           logic [TAGE_TX_PRED_WIDTH-1:0]           pred_cnt;
                           logic [TAGE_TX_TAG_WIDTH-1:0]            tag;
                           logic [TAGE_TX_USEFUL_WIDTH-1:0]         u_cnt;
                          } tage_tx_field_pkg;

    typedef struct packed {
                           logic                                    valid;
                           logic [TAGE_TX_PRED_WIDTH-1:0]           pred_cnt;
                           logic [TAGE_TX_INDEX_WIDTH-1:0]          index;
                           logic [TAGE_TX_TAG_WIDTH-1:0]            tag;
                           logic [TAGE_TX_USEFUL_WIDTH-1:0]         u_cnt;
                          } tage_tx_entry_pkg;

    typedef struct packed {
                           logic [TAGE_BASE_INDEX_WIDTH-1:0]        tb_idx;
                           logic [TAGE_BASE_PRED_WIDTH-1:0]         tb_pred;
                           tage_tx_entry_pkg  [TAGE_TABLE_NUM-1:0]  tx_entry ;
                           logic                                    pred_taken;
                           logic                                    pred_diff;
                           logic [TAGE_TABLE_NUM:0]                 prvd_idx;
                          } tage_entry_pkg;

    typedef struct packed {
                           logic                                    taken;
                           logic                                    mispred;
                           logic [TAGE_TABLE_NUM-1:0]               alloc_id;
                           logic                                    tb_pred_add;
                           logic                                    tb_pred_sub;
                          } tage_update_pkg;

    typedef struct packed {
                           tage_entry_pkg                           entry;
                           tage_update_pkg                          update;
                          } tage_entry_buffer_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                                 pred_pc;
                           logic [TAGE_BASE_INDEX_WIDTH-1:0]                      tb_idx;
                           logic [TAGE_BASE_PRED_WIDTH-1:0]                       tb_pred;
                           logic [TAGE_TABLE_NUM-1:0] [TAGE_TX_INDEX_WIDTH-1:0]   tx_hash_idx ;
                           logic [TAGE_TABLE_NUM-1:0] [TAGE_TX_TAG_WIDTH-1:0]     tx_hash_tag ;
                           tage_tx_field_pkg                 [TAGE_TABLE_NUM-1:0] tx_entry;
                           logic [TAGE_USE_ALT_WIDTH-1:0]                         use_alt_cnt;
                          } tage_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           logic                                    taken;
                           logic                                    taken_err;
                          } tage_res_pkg;


    typedef struct packed {
                           logic                                    valid;
                           logic [BTB_TAG_WIDTH-1:0]                tag;
                           logic [ADDR_WIDTH-1:0]                   tgt_pc;
                           logic [BPU_OFFSET_WIDTH-1:0]             offset;
                           logic                                    is_cext;
                           logic                                    carry;
                          } btb_entry_way_pkg;

    typedef struct packed {
                           logic [BTB_WAY_NUM-2:0]                  node;    // plru
                           btb_entry_way_pkg [BTB_WAY_NUM-1:0]      entry_way;
                          } btb_entry_pkg;

    typedef struct packed {
                           logic [BTB_INDEX_WIDTH-1:0]              index; // pred
                           logic [BTB_TAG_WIDTH-1:0]                tag;   // pred
                           logic [BTB_WAY_NUM-1:0]                  way_hit;
                           logic                                    real_taken;
                           btb_entry_pkg                            entry;
                          } btb_entry_buffer_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           logic [BTB_INDEX_WIDTH-1:0]              hash_idx;
                           logic [BTB_TAG_WIDTH-1:0]                hash_tag;
                           btb_entry_pkg                            entry_ack_rdata;
                           logic [ADDR_WIDTH-1 :0]                  align_pc_boundary;
                           logic [ADDR_WIDTH-1 :0]                  align_offset;
                          } btb_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           tage_entry_buffer_pkg                    tage_entry;
                           btb_entry_buffer_pkg                     btb_entry;
                          } entry_buffer_pkg;



    typedef struct packed {
                           logic [1:0]                              inst_type; // 0: call, 1: ret
                           logic [ADDR_WIDTH-1:0]                   pred_pc;
                           logic [ADDR_WIDTH-1:0]                   pc;
                           logic [BPU_OFFSET_WIDTH-1:0]             offset;
                           logic                                    is_cext;
                           logic                                    carry;
                           logic [ADDR_WIDTH-1:0]                   tgt_pc;
                           logic                                    taken;
                          } ras_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]             pred_pc;
                           logic                              taken;
                           logic [ADDR_WIDTH-1:0]             tgt_pc;
                           logic [BPU_OFFSET_WIDTH-1:0]       offset;
                           logic                              is_cext;
                           logic                              carry;
                          } bypass_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]             pc;
                           logic                              is_call;
                           logic                              is_ret;
                           logic                              taken_err;
                           logic                              taken_pend;
                           logic                              is_last;
                           bypass_pkg                         bypass;
                          } be_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1:0]             pred_pc;
                           logic [ADDR_WIDTH-1:0]             tgt_pc;
                           logic [BPU_OFFSET_WIDTH-1:0]       offset;
                           logic                              is_cext;
                           logic                              carry;
                           logic [INST_WIDTH_32-1:0]          inst_pld;
                           logic                              is_call;
                           logic                              is_ret;
                           logic                              is_last;
                           logic                              taken;
                          } fe_bypass_pkg;

    typedef struct packed {
                           logic [INST_WIDTH_32-1:0]          inst;
                           be_pkg                             bypass;
                          } fetch_queue_pkg;

    typedef struct packed {
                           logic [INST_WIDTH-1         :0]     inst_pld             ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     inst_rd              ;
                           logic                               inst_rd_en           ;
                           logic                               inst_fp_rd_en        ;
                           logic                               c_ext                ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [31                   :0]     reg_rs1_val          ;
                           logic [31                   :0]     reg_rs2_val          ;
                           logic [31                   :0]     reg_rs3_val          ;
                           logic [31                   :0]     inst_imm             ;
                          } eu_pkg;

    typedef struct packed {
                           logic [INST_WIDTH-1         :0]     instruction_pld      ;
                           logic [INST_IDX_WIDTH-1     :0]     instruction_idx      ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     reg_index            ;
                           logic                               inst_rd_en           ;
                           logic                               mext_c_ext           ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [2                    :0]     funct3               ;
                           logic [REG_WIDTH-1          :0]     rs1_val              ;
                           logic [REG_WIDTH-1          :0]     rs2_val              ;
                          } mext_pkg;

    typedef struct packed {
                           logic [INST_WIDTH-1         :0]     inst_pld             ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     inst_rd              ;
                           logic                               inst_rd_en           ;
                           logic                               inst_fp_rd_en        ;
                           logic                               c_ext                ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [4                    :0]     reg_rs1              ;
                           logic [4                    :0]     reg_rs2              ;
                           logic [4                    :0]     reg_rs3              ;
                           logic [31                   :0]     inst_imm             ;
                           logic                               use_rs1_fp_en        ;
                           logic                               use_rs2_fp_en        ;
                           logic                               use_rs3_fp_en        ;
                           logic                               use_rs1_en           ;
                           logic                               use_rs2_en           ;
                           logic                               goto_lsu             ;
                           logic                               goto_ldu             ;
                           logic                               goto_stu             ;
                           logic                               goto_alu             ;
                           logic                               goto_err             ;
                           logic                               goto_mext            ;
                           logic                               goto_csr             ;
                           logic                               goto_float           ;
                           logic                               goto_custom          ;
                          } decode_pkg;

    typedef struct packed {
                           logic [INST_WIDTH-1         :0]     inst_pld             ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     inst_rd              ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic                               inst_rd_en           ;
                           logic                               inst_fp_rd_en        ;
                           logic                               c_ext                ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [31                   :0]     reg_rs1_val          ;
                           logic [31                   :0]     reg_rs2_val          ;
                           logic [31                   :0]     reg_rs3_val          ;
                           logic [31                   :0]     inst_imm             ;
                           logic                               stu_en               ;
                           logic                               ldu_en               ;
                           logic                               lsid                 ;
                          } lsu_pkg;

    typedef struct packed {
                           logic [REG_WIDTH-1          :0]     mem_req_data         ;
                           logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
                           logic [3                    :0]     mem_req_strb         ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [31                   :0]     inst_pc              ;
                           logic                               lsid                 ;
                           logic                               c_ext                ;
                          } stu_pkg;

    typedef struct packed {
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [ADDR_WIDTH-1         :0]     inst_pc              ;
                           logic [REG_WIDTH-1          :0]     mem_req_data         ;
                           logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
                           logic [3                    :0]     mem_req_strb         ;
                           logic                               c_ext                ;
                          } stq_pkg;

    typedef struct packed {
                           logic [DATA_WIDTH-1         :0]     mem_req_data         ;
                           logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
                           logic [FETCH_SB_WIDTH-1     :0]     mem_req_sideband     ;
                           logic                               mem_req_opcode       ;
                           logic [3                    :0]     mem_req_strb         ;
                          } mem_req_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
                           logic [3                    :0]     mem_req_strb         ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     inst_rd              ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic                               inst_rd_en           ;
                           logic                               inst_fp_rd_en        ;
                           logic [2                    :0]     funct3               ;
                           logic                               lsid                 ;
                           logic [31                   :0]     inst_pc              ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic                               c_ext                ;
                          } ldu_pkg;

    typedef struct packed {
                           logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
                           logic [3                    :0]     mem_req_strb         ;
                           logic [PHY_REG_ID_WIDTH-1   :0]     inst_rd              ;
                           logic [4                    :0]     arch_reg_index       ;
                           logic                               inst_rd_en           ;
                           logic [2                    :0]     funct3               ;
                           logic [INST_IDX_WIDTH-1     :0]     inst_id              ;
                           logic [31                   :0]     inst_pc              ;
                           logic                               inst_fp_rd_en        ;
                           logic                               c_ext                ;
                          } ldq_pkg;

    // typedef struct packed {
    //     logic [ADDR_WIDTH-1         :0]     mem_req_addr         ;
    //     logic [FETCH_SB_WIDTH-1     :0]     mem_req_sideband     ;
    //     logic                               mem_req_opcode       ;
    //     logic [3                    :0]     mem_req_strb         ;
    // } ld_mem_req_pkg;

    typedef struct packed {
                           logic [DATA_WIDTH-1         :0]     mem_ack_data         ;
                           logic [FETCH_SB_WIDTH-1     :0]     mem_ack_sideband     ;
                          } mem_ack_pkg;
    // mstatus register
    typedef struct packed {
                           logic       sd      ;       // done
                           logic [7:0] wpri3   ;       // done
                           logic       tsr     ;       // done
                           logic       tw      ;       // done
                           logic       tvm     ;       // done
                           logic       mxr     ;       // done
                           logic       sum     ;       // done
                           logic       mprv    ;       // done
                           logic [1:0] xs      ;       // done
                           logic [1:0] fs      ;       // done
                           logic [1:0] mpp     ;       // done
                           logic [1:0] vs      ;       // done
                           logic       spp     ;       // done
                           logic       mpie    ;       // done
                           logic       ube     ;       // done
                           logic       spie    ;       // done
                           logic       wpri2   ;       // done
                           logic       mie     ;       // done
                           logic       wpri1   ;       // done
                           logic       sie     ;       // done
                           logic       wpri0   ;       // done
                          } mstatus_t;


    // machine interrupts pending register
    typedef struct packed {
                           logic [19:0]    unused6 ;
                           logic           meip    ;
                           logic           unused5 ;
                           logic           seip    ;
                           logic           unused4 ;
                           logic           mtip    ;
                           logic           unused3 ;
                           logic           stip    ;
                           logic           unused2 ;
                           logic           msip    ;
                           logic           unused1 ;
                           logic           ssip    ;
                           logic           unused0 ;
                          } mip_t;

    // machine interrupts enabled register
    typedef struct packed {
                           logic [19:0]    unused6 ;
                           logic           meie    ;
                           logic           unused5 ;
                           logic           seie    ;
                           logic           unused4 ;
                           logic           mtie    ;
                           logic           unused3 ;
                           logic           stie    ;
                           logic           unused2 ;
                           logic           msie    ;
                           logic           unused1 ;
                           logic           ssie    ;
                           logic           unused0 ;
                          } mie_t;


    typedef enum logic [31:0] {
                               // interrupt codes have the top bit set to 1.
                               MCAUSE_SSI = {1'b1, 31'd1},
                               MCAUSE_MSI = {1'b1, 31'd3},
                               MCAUSE_STI = {1'b1, 31'd5},
                               MCAUSE_MTI = {1'b1, 31'd7},
                               MCAUSE_SEI = {1'b1, 31'd9},
                               MCAUSE_MEI = {1'b1, 31'd11},

                               MCAUSE_INSTR_MISALIGN = 32'd0,
                               MCAUSE_INSTR_FAULT    = 32'd1,
                               MCAUSE_ILLEGAL_INSTR  = 32'd2,
                               MCAUSE_BREAK          = 32'd3,
                               MCAUSE_LOAD_MISALIGN  = 32'd4,
                               MCAUSE_LOAD_FAULT     = 32'd5,
                               MCAUSE_STORE_MISALIGN = 32'd6,
                               MCAUSE_STORE_FAULT    = 32'd7,
                               MCAUSE_ECALL_U        = 32'd8,
                               MCAUSE_ECALL_S        = 32'd9,
                               MCAUSE_ECALL_M        = 32'd11
                              } mcause_t;


    typedef enum logic [4:0] {
                              AMOLR       = 5'b00010,
                              AMOSC       = 5'b00011,
                              AMOSWAP     = 5'b00001,
                              AMOADD      = 5'b00000,
                              AMOXOR      = 5'b00100,
                              AMOAND      = 5'b01100,
                              AMOOR       = 5'b01000,
                              AMOMIN      = 5'b10000,
                              AMOMAX      = 5'b10100,
                              AMOMINU     = 5'b11000,
                              AMOMAXU     = 5'b11100
                             } amo_opcode_t;

    typedef enum logic [4:0] {
                              FLOAT_ADD           = 5'b00000,
                              FLOAT_SUB           = 5'b00001,
                              FLOAT_MUL           = 5'b00010,
                              FLOAT_DIV           = 5'b00011,
                              FLOAT_SQRT          = 5'b01011,
                              FLOAT_SGNJ          = 5'b00100,
                              FLOAT_MINMAX        = 5'b00101,
                              FLOAT_CVT_WS        = 5'b11000,
                              FLOAT_MVXW_CLASS    = 5'b11100,
                              FLOAT_CMP           = 5'b10100,
                              FLOAT_CVT_SW        = 5'b11010,
                              FLOAT_MVWX          = 5'b11110
                             } float_funct5;

    typedef enum logic [2:0] {
                              FSGNJ_SGNJ          = 3'b000,
                              FSGNJ_SGNJ_N        = 3'b001,
                              FSGNJ_SGNJ_X        = 3'b010
                             } float_sgnj_funct3;

    typedef enum logic [2:0] {
                              FMINMAX_MIN         = 3'b000,
                              FMINMAX_MAX         = 3'b001
                             } float_min_max_funct3;

    typedef enum logic [4:0] {
                              FCVT_W             = 5'b00000,
                              FCVT_WU            = 5'b00001
                             } float_cvt;

    typedef enum logic [2:0] {
                              FCMP_FEQ            = 3'b010,
                              FCMP_FLT            = 3'b001,
                              FCMP_FLE            = 3'b000
                             } float_cmp_funct3;

    typedef enum logic [2:0] {
                              FMVCL_MV            = 3'b000,
                              FMVCL_CLASS         = 3'b001
                             } float_mvxw_class_funct3;

    typedef enum logic [2:0] {
                              FRND_RNE            = 3'b000,
                              FRND_RTZ            = 3'b001,
                              FRND_RDN            = 3'b010,
                              FRND_RUP            = 3'b011,
                              FRND_RMM            = 3'b100,
                              FRND_RES0           = 3'b101,
                              FRND_RES1           = 3'b110,
                              FRND_DYN            = 3'b111
                             } float_rnd;
//typedef enum logic [2:0] {
//    CF3_ADDI4SPN    = 3'b000,
//    CF3_LW          = 3'b010,
//    CF3_SW          = 3'b110
//} cfunct3_op00_t;


//typedef enum logic [2:0] {


//} cfunct3_op01_t;

//typedef enum logic [2:0] {
//    CF3_SLLI        = 3'b000,
//    CF3_LWSP        = 3'b010,
//    CF3_JMEJA       = 3'b100,
//    CF3_SWSP        = 3'b110
//} cfunct3_op10_t;

endpackage





// internal, decoded opcodes
// typedef enum logic [5:0] {
//     INTERNAL_INST_LUI,
//     INTERNAL_INST_AUIPC,
//     INTERNAL_INST_JAL,
//     INTERNAL_INST_JALR,
//     INTERNAL_INST_BEQ,
//     INTERNAL_INST_BNE,
//     INTERNAL_INST_BLT,
//     INTERNAL_INST_BGE,
//     INTERNAL_INST_BLTU,
//     INTERNAL_INST_BGEU,
//     INTERNAL_INST_LOAD,
//     INTERNAL_INST_STORE,
//     //INTERNAL_INST_LB,
//     //INTERNAL_INST_LH,
//     //INTERNAL_INST_LW,
//     //INTERNAL_INST_LBU,
//     //INTERNAL_INST_LHU,
//     //INTERNAL_INST_SB,
//     //INTERNAL_INST_SH,
//     //INTERNAL_INST_SW,
//     INTERNAL_INST_ADDI,
//     INTERNAL_INST_SLTI,
//     INTERNAL_INST_SLTIU,
//     INTERNAL_INST_XORI,
//     INTERNAL_INST_ORI,
//     INTERNAL_INST_ANDI,
//     INTERNAL_INST_SLLI,
//     INTERNAL_INST_SRLI,
//     INTERNAL_INST_SRAI,
//     INTERNAL_INST_ADD,
//     INTERNAL_INST_SUB,
//     INTERNAL_INST_SLL,
//     INTERNAL_INST_SLT,
//     INTERNAL_INST_SLTU,
//     INTERNAL_INST_XOR,
//     INTERNAL_INST_SRL,
//     INTERNAL_INST_SRA,
//     INTERNAL_INST_OR,
//     INTERNAL_INST_AND,
//     INTERNAL_INST_FENCE,
//     INTERNAL_INST_FENCE_I,
//     INTERNAL_INST_ECALL,
//     INTERNAL_INST_EBREAK,
//     INTERNAL_INST_INVALID
// } internal_inst_opcode;
