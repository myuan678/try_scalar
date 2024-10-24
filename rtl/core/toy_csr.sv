
module toy_csr
    import toy_pack::*;
(
    input  logic                      clk                 ,
    input  logic                      rst_n               ,

    output logic                      intr_instruction_vld,
    input  logic                      intr_instruction_rdy,

    input  logic                      instruction_vld     ,
    output logic                      instruction_rdy     ,
    input  logic [INST_WIDTH-1:0]     instruction_pld     ,
    input  logic [INST_IDX_WIDTH-1:0] instruction_idx     ,
    input  logic                      instruction_is_intr ,
    input  logic                      csr_c_ext           ,
    input  logic [PHY_REG_ID_WIDTH-1:0]inst_rd_idx        ,
    input  logic                      inst_rd_en          ,
    input  logic [4:0]                arch_reg_index      ,
    input  logic [REG_WIDTH-1:0]      rs1_val             ,
    input  logic [REG_WIDTH-1:0]      rs2_val             ,
    input  logic [ADDR_WIDTH-1:0]     pc                  ,
    
    // reg access
    output logic [PHY_REG_ID_WIDTH-1:0]reg_index          ,
    output logic                      reg_wr_en           ,
    output logic [REG_WIDTH-1:0]      reg_val             ,
    output logic [INST_IDX_WIDTH-1:0] reg_inst_idx        ,
    output logic                      inst_commit_en      ,
    output commit_pkg                 csr_commit_pld      ,

    input  logic [63:0]               csr_INSTRET         ,

    // float csr
    output logic [31:0]               csr_FCSR            ,
    input  logic [4:0]                csr_FFLAGS          ,
    input  logic                      csr_FFLAGS_en       ,
    input  logic                      cancel_edge_en      ,
    input  logic [7:0]                FCSR_backup         ,
    // pc update
    output logic                      pc_release_en       ,
    output logic                      pc_update_en        ,
    output logic [ADDR_WIDTH-1:0]     pc_val              ,

    // interrupt
    input logic                       intr_meip           ,
    input logic                       intr_msip         
);

    logic [11:0]            funct12     ;
    logic [2:0]             funct3      ;
    logic [11:0]            csr_addr    ;
    logic [REG_WIDTH-1:0]   csr_rdata   ;
    logic [REG_WIDTH-1:0]   csr_wdata   ;
    logic                   csr_wren    ;
    logic [4:0]             csr_imm     ;

    logic cancel_edge_en_d;

    logic exception_en  ;
    logic mret_en       ;

    logic [63:0]            csr_CYCLE;
    logic [63:0]            csr_MTIMECMP;
    logic [63:0]            csr_CANCEL;
    logic [REG_WIDTH-1:0]   csr_MTVEC;
    mstatus_t               csr_MSTATUS;
    mstatus_t               csr_MSTATUS_wr;
    logic                   csr_MSTATUS_wren;
    mip_t                   csr_MIP;
    mie_t                   csr_MIE;
    logic [31:0]            csr_MEDELEG;
    logic [31:0]            csr_MIDELEG;
    logic [REG_WIDTH-1:0]   csr_MTVAL;
    logic [REG_WIDTH-1:0]   csr_MEPC;
    logic [REG_WIDTH-1:0]   csr_MSCRATCH;
    logic [REG_WIDTH-1:0]   csr_MCAUSE;


    assign funct3    = instruction_pld`INST_FIELD_FUNCT3    ;
    assign csr_imm   = instruction_pld`INST_FIELD_RS1       ;

    //assign reg_index = instruction_pld`INST_FIELD_RD        ;
    assign reg_index = inst_rd_idx                          ;
    assign reg_val   = csr_rdata                            ;
    assign reg_wr_en = csr_wren                             ;
    assign reg_inst_idx = instruction_idx                   ;
    assign inst_commit_en = instruction_vld                 ;
    
    assign csr_addr  = instruction_pld`INST_FIELD_FUNCT12   ;
    assign funct12   = instruction_pld`INST_FIELD_FUNCT12   ;

    assign instruction_rdy = 1'b1;

    //===================
    // commit 
    //===================

    assign csr_commit_pld.inst_id = instruction_idx;
    assign csr_commit_pld.inst_pc = pc;
    assign csr_commit_pld.inst_nxt_pc = pc_update_en ? pc_val : (csr_c_ext ? pc+2 : pc + 4);
    assign csr_commit_pld.rd_en = inst_rd_en;
    assign csr_commit_pld.fp_rd_en = 1'b0;
    assign csr_commit_pld.arch_reg_index = arch_reg_index;
    assign csr_commit_pld.phy_reg_index = reg_index;
    assign csr_commit_pld.stq_commit_entry_en = 1'b0;
    // for bpu 
    assign csr_commit_pld.is_cext   = instruction_pld[1:0]!=2'b11;
    assign csr_commit_pld.inst_val  = instruction_pld;
    assign csr_commit_pld.is_call   = 0;
    assign csr_commit_pld.is_ret    = 0;
    assign csr_commit_pld.is_ind    = 0;

    always_comb begin
        csr_commit_pld.FCSR_en = 1'b0;
        csr_commit_pld.FCSR_data = 8'b0;
        if(csr_wren)begin
            case (csr_addr)
                CSR_ADDR_FFLAGS : begin
                    csr_commit_pld.FCSR_data     = {csr_FCSR[7:5],csr_wdata[4:0]};
                    csr_commit_pld.FCSR_en = 8'h1f;
                end
                CSR_ADDR_FRM    : begin
                    csr_commit_pld.FCSR_data     = {csr_wdata[2:0],csr_FCSR[4:0]};
                    csr_commit_pld.FCSR_en = 8'he0;
                end
                CSR_ADDR_FCSR   : begin
                    csr_commit_pld.FCSR_data     = csr_wdata[7:0]; 
                    csr_commit_pld.FCSR_en = 8'hff;
                end
            endcase
        end
    end

    always_comb begin
        exception_en = 1'b0;
        if(funct3 == F3_PRIV) begin
            if ((funct12==F12_ECALL)|(funct12==F12_EBREAK)) begin
                exception_en = instruction_vld && instruction_rdy;
            end
        end
    end

    always_comb begin
        mret_en = 1'b0;
        if(funct3 == F3_PRIV) begin
            if ((funct12==F12_MRET)) begin
                mret_en = instruction_vld && instruction_rdy;
            end
        end    
    end


    // always_comb begin
    //     if( (funct3 == F3_CSRRW  )|
    //         (funct3 == F3_CSRRS  )|
    //         (funct3 == F3_CSRRC  )|
    //         (funct3 == F3_CSRRWI )|
    //         (funct3 == F3_CSRRSI )|
    //         (funct3 == F3_CSRRCI ))     csr_wren = instruction_vld && instruction_rdy;
    //     else                            csr_wren = 1'b0;
    // end

    assign csr_wren = inst_rd_en & instruction_vld;

    
    always_comb begin
        case(funct3)
        F3_CSRRW    : csr_wdata = rs1_val               ;
        F3_CSRRS    : csr_wdata = csr_rdata | rs1_val   ;
        F3_CSRRC    : csr_wdata = csr_rdata & ~rs1_val  ;
        F3_CSRRWI   : csr_wdata = csr_imm               ;
        F3_CSRRSI   : csr_wdata = csr_rdata | csr_imm   ;
        F3_CSRRCI   : csr_wdata = csr_rdata & ~csr_imm  ;
        //F3_PRIV     : 
        default     : csr_wdata = {REG_WIDTH{1'b0}}     ;
        endcase
    end



    always_comb begin
        if(exception_en) begin
            pc_release_en = 1'b1        ;
            pc_update_en  = 1'b1        ;
            pc_val        = csr_MTVEC   ;
        end
        else if(mret_en) begin
            pc_release_en = 1'b1        ;
            pc_update_en  = 1'b1        ;
            pc_val        = csr_MEPC    ;
        end
        else begin
            pc_release_en = 1'b0        ;
            pc_update_en  = 1'b0        ;
            pc_val        = 'b0         ;
        end
    end


    // Interrupt Generation ======================================================================

    logic interrupt_instruction_sent    ;
    logic interrupt_en                  ;

    assign interrupt_en = instruction_vld & instruction_rdy & instruction_is_intr;


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          interrupt_instruction_sent <= 1'b0;
        else if(intr_instruction_vld & intr_instruction_rdy)                interrupt_instruction_sent <= 1'b1;
        else if(interrupt_en)                                               interrupt_instruction_sent <= 1'b0;
    end


    assign intr_instruction_vld = (~interrupt_instruction_sent) & csr_MSTATUS.mie & (
        ( csr_MIE.meie & csr_MIP.meip ) |
        ( csr_MIE.mtie & csr_MIP.mtip ) |
        ( csr_MIE.msie & csr_MIP.msip )
    );




    //============================================================================================

    always_comb begin
        case(csr_addr)

        // Unprivileged Counter/Timers ==================================================
        CSR_ADDR_CYCLE      : csr_rdata = csr_CYCLE[REG_WIDTH-1:0]                  ;
        CSR_ADDR_CYCLEH     : csr_rdata = csr_CYCLE[2*REG_WIDTH-1:REG_WIDTH]        ;
        CSR_ADDR_TIME       : csr_rdata = csr_CYCLE[REG_WIDTH-1:0]                  ;       // tmp
        CSR_ADDR_TIMEH      : csr_rdata = csr_CYCLE[2*REG_WIDTH-1:REG_WIDTH]        ;
        CSR_ADDR_INSTRET    : csr_rdata = csr_INSTRET[REG_WIDTH-1:0]                ;
        CSR_ADDR_INSTRETH   : csr_rdata = csr_INSTRET[2*REG_WIDTH-1:REG_WIDTH]      ;
        CSR_ADDR_CANCEL     : csr_rdata = csr_CANCEL[REG_WIDTH-1:0]                 ;       
        CSR_ADDR_CANCELH    : csr_rdata = csr_CANCEL[2*REG_WIDTH-1:REG_WIDTH]       ;
        
        // fcsr =========================================================================
        CSR_ADDR_FFLAGS     : csr_rdata = {27'b0,csr_FCSR[4:0]}                     ;
        CSR_ADDR_FRM        : csr_rdata = {29'b0,csr_FCSR[7:5]}                     ;
        CSR_ADDR_FCSR       : csr_rdata = csr_FCSR                                  ;

        // Machine Information Registers ================================================
        CSR_ADDR_MVENDORID  : csr_rdata = 32'b0                                     ;       // use 0 because this is not a commercial impl.
        CSR_ADDR_MARCHID    : csr_rdata = 32'b0                                     ;       // 
        CSR_ADDR_MIMPID     : csr_rdata = 32'b0                                     ;       //
        CSR_ADDR_MHARTID    : csr_rdata = 32'b0                                     ;
        //CSR_ADDR_MCONFIGPTR : csr_rdata = 32'b0                                     ;       // config ptr not impl.

        // Machine Trap Setup ===========================================================
        CSR_ADDR_MSTATUS    : csr_rdata = csr_MSTATUS                               ;
        CSR_ADDR_MISA       : csr_rdata = 32'b01000000_00000000_00000001_00000000   ;       // stands for rv32i
        CSR_ADDR_MEDELEG    : csr_rdata = csr_MEDELEG                               ;
        CSR_ADDR_MIDELEG    : csr_rdata = csr_MIDELEG                               ;
        CSR_ADDR_MIE        : csr_rdata = csr_MIE                                   ;
        CSR_ADDR_MTVEC      : csr_rdata = csr_MTVEC                                 ;       // trap handler base address.
        //CSR_ADDR_MCOUNTEREN : csr_rdata = 32'b0                                     ;       // not impl for only M mode system.
        //CSR_ADDR_MSTATUSH   : csr_rdata = 32'b0                                     ;       // mbe=0, sbe=0, always little endian

        // Machine Trap Handling ========================================================
        CSR_ADDR_MSCRATCH   : csr_rdata = csr_MSCRATCH                              ;
        CSR_ADDR_MEPC       : csr_rdata = csr_MEPC                                  ;
        CSR_ADDR_MCAUSE     : csr_rdata = csr_MCAUSE                                ;
        CSR_ADDR_MTVAL      : csr_rdata = csr_MTVAL                                 ;
        CSR_ADDR_MIP        : csr_rdata = csr_MIP                                   ;
        //CSR_ADDR_MTINST     : csr_rdata = 32'b0                                     ;       // not impl
        //CSR_ADDR_MTVAL2     : csr_rdata = 32'b0                                     ;       // not impl

        // Machine Counter/Timers =======================================================
        CSR_ADDR_MCYCLE     : csr_rdata = csr_CYCLE[REG_WIDTH-1:0]                  ;
        CSR_ADDR_MCYCLEH    : csr_rdata = csr_CYCLE[2*REG_WIDTH-1:REG_WIDTH]        ;
        CSR_ADDR_MINSTRET   : csr_rdata = csr_INSTRET[REG_WIDTH-1:0]                ;
        CSR_ADDR_MINSTRETH  : csr_rdata = csr_INSTRET[2*REG_WIDTH-1:REG_WIDTH]      ;

        // Non-Standard MTIME Compare ===================================================
        CSR_ADDR_MTIMECMP   : csr_rdata = csr_MTIMECMP[31:0]                        ;
        CSR_ADDR_MTIMECMPH  : csr_rdata = csr_MTIMECMP[63:32]                       ;

        default             : csr_rdata = 32'b0                                     ;
        endcase
    end

 


    // CSR CYCLE =========================================
    

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)  csr_CYCLE <= 64'b0;
        else        csr_CYCLE <= csr_CYCLE + 1'b1;
    end
    // CSR CANCEL =========================================
    

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            csr_CANCEL <= 64'b0;
        end  
        else if(cancel_edge_en) begin
            csr_CANCEL <= csr_CANCEL + 1'b1;
        end        
    end


    // CSR TIMECMP =======================================

    // non-standard csr.


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                              csr_MTIMECMP[31:0]   <= 32'b0       ;
        else if(csr_wren & (csr_addr == CSR_ADDR_MTIMECMP))     csr_MTIMECMP[31:0]   <= csr_wdata   ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                              csr_MTIMECMP[63:32] <= 32'b0        ;
        else if(csr_wren & (csr_addr == CSR_ADDR_MTIMECMPH))    csr_MTIMECMP[63:32] <= csr_wdata    ;
    end



    // CSR MTVEC =========================================


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            csr_MTVEC[REG_WIDTH-1:2] <= 'b0;
            csr_MTVEC[1:0]           <= 'b0;
        end
        else if(csr_wren & (csr_addr == CSR_ADDR_MTVEC)) begin
            csr_MTVEC[REG_WIDTH-1:2] <= csr_wdata[REG_WIDTH-1:2];
            if(csr_wdata[1]==1'b0) begin //[1:0] only writeable when equal to 2'b00 or 2'b01;
                csr_MTVEC[1:0] <= csr_wdata[1:0];
            end
        end
    end



    // CSR MSTATUS & MSTATUSH ============================


    assign csr_MSTATUS_wren = csr_wren & (csr_addr == CSR_ADDR_MSTATUS);

    //assign csr_MSTATUS = 0;//todo

    assign csr_MSTATUS_wr = csr_wdata;

    assign csr_MSTATUS.ube  = 1'b0; // always litte endian
    assign csr_MSTATUS.tvm  = 1'b0; // read only 0 when s-mode is not supported.
    assign csr_MSTATUS.tsr  = 1'b0; // read only 0 when s-mode is not supported.
    assign csr_MSTATUS.tw   = 1'b0; // read only 0 in m-mode only system.
    assign csr_MSTATUS.mxr  = 1'b0; // read only 0 when s-mode is not supported.
    assign csr_MSTATUS.sum  = 1'b0; // read only 0 when s-mode is not supported.
    assign csr_MSTATUS.mprv = 1'b0; // read only 0 when s-mode is not supported.
    
    assign csr_MSTATUS.mpp  = 2'b0; // read only 0 in m-mode only system.
    assign csr_MSTATUS.spp  = 1'b0; // read only 0 in m-mode only system.

    assign csr_MSTATUS.xs   = 2'b0;  // user extension always clean.
    assign csr_MSTATUS.fs   = 2'b0;  // no float unit.
    assign csr_MSTATUS.vs   = 2'b0;  // no vector unit.
    assign csr_MSTATUS.sd   = 1'b0;  // summarize for above, always clean.

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            csr_MSTATUS.wpri0   <= 'b0              ;
            csr_MSTATUS.wpri1   <= 'b0              ;
            csr_MSTATUS.wpri2   <= 'b0              ;
            csr_MSTATUS.wpri3   <= 'b0              ;
        end
        else if(csr_wren & (csr_addr == CSR_ADDR_MSTATUS)) begin
            csr_MSTATUS.wpri0   <= csr_MSTATUS_wr   ;
            csr_MSTATUS.wpri1   <= csr_MSTATUS_wr   ;
            csr_MSTATUS.wpri2   <= csr_MSTATUS_wr   ;
            csr_MSTATUS.wpri3   <= csr_MSTATUS_wr   ;
        end
    end



    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  csr_MSTATUS.sie     <= 1'b0                 ;
        else if(exception_en)       csr_MSTATUS.sie     <= 1'b0                 ;
        else if(mret_en)            csr_MSTATUS.sie     <= csr_MSTATUS.spie     ;
        else if(csr_MSTATUS_wren)   csr_MSTATUS.sie     <= csr_MSTATUS_wr.sie   ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  csr_MSTATUS.mie     <= 1'b0                 ;
        else if(exception_en)       csr_MSTATUS.mie     <= 1'b0                 ;
        else if(mret_en)            csr_MSTATUS.mie     <= csr_MSTATUS.mpie     ;
        else if(csr_MSTATUS_wren)   csr_MSTATUS.mie     <= csr_MSTATUS_wr.mie   ;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  csr_MSTATUS.mpie    <= 1'b0                 ;
        else if(exception_en)       csr_MSTATUS.mpie    <= csr_MSTATUS.mie      ;
        else if(mret_en)            csr_MSTATUS.mpie    <= 1'b1                 ;
        else if(csr_MSTATUS_wren)   csr_MSTATUS.mpie    <= csr_MSTATUS_wr.mpie  ;       
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                  csr_MSTATUS.spie    <= 1'b0                 ;
        else if(exception_en)       csr_MSTATUS.spie    <= csr_MSTATUS.sie      ;
        else if(mret_en)            csr_MSTATUS.spie    <= 1'b1                 ;
        else if(csr_MSTATUS_wren)   csr_MSTATUS.spie    <= csr_MSTATUS_wr.spie  ;
    end




    // CSR MIP ===========================================



    assign csr_MIP.unused0 = 1'b0   ;
    assign csr_MIP.unused1 = 1'b0   ;
    assign csr_MIP.unused2 = 1'b0   ;
    assign csr_MIP.unused3 = 1'b0   ;
    assign csr_MIP.unused4 = 1'b0   ;
    assign csr_MIP.unused5 = 1'b0   ;
    assign csr_MIP.unused6 = 20'b0  ;

    assign csr_MIP.ssip = 1'b0                          ; 
    assign csr_MIP.msip = intr_msip                     ; 
    assign csr_MIP.stip = 1'b0                          ; 
    assign csr_MIP.mtip = (csr_CYCLE > csr_MTIMECMP)    ; 
    assign csr_MIP.seip = 1'b0                          ; 
    assign csr_MIP.meip = intr_meip                     ; 

 

    // CSR MIE ===========================================



    assign csr_MIE.unused0 = 1'b0   ;
    assign csr_MIE.unused1 = 1'b0   ;
    assign csr_MIE.unused2 = 1'b0   ;
    assign csr_MIE.unused3 = 1'b0   ;
    assign csr_MIE.unused4 = 1'b0   ;
    assign csr_MIE.unused5 = 1'b0   ;
    assign csr_MIE.unused6 = 20'b0  ;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            csr_MIE.ssie    <= 1'b0             ;
            csr_MIE.msie    <= 1'b0             ;
            csr_MIE.stie    <= 1'b0             ;
            csr_MIE.mtie    <= 1'b0             ;
            csr_MIE.seie    <= 1'b0             ;
            csr_MIE.meie    <= 1'b0             ;
        end
        else if(csr_wren & (csr_addr == CSR_ADDR_MIE)) begin
            csr_MIE.ssie    <= csr_wdata[1]     ;
            csr_MIE.msie    <= csr_wdata[3]     ;
            csr_MIE.stie    <= csr_wdata[5]     ;
            csr_MIE.mtie    <= csr_wdata[7]     ;
            csr_MIE.seie    <= csr_wdata[9]     ;
            csr_MIE.meie    <= csr_wdata[11]    ;
        end
    end



    // CSR MEDELEG =========================================


    assign csr_MEDELEG = 32'b0;                                     // disable exception delegation.



    // CSR MIDELEG =========================================



    assign csr_MIDELEG = 32'b0;                                     // disable interrupt delegation.




    // CSR MTVAL ===========================================



    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                          csr_MTVAL <= 32'b0              ;
        else if(exception_en)                               csr_MTVAL <= instruction_pld    ;
        else if(csr_wren & (csr_addr == CSR_ADDR_MTVAL))    csr_MTVAL <= csr_wdata          ;
    end



    // CSR MEPC ============================================


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                          csr_MEPC <= 32'b0       ;
        else if(exception_en)                               csr_MEPC <= pc          ;
        else if(csr_wren & (csr_addr == CSR_ADDR_MEPC))     csr_MEPC <= csr_wdata   ;
    end



    // CSR MSCRATCH ========================================




    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                          csr_MSCRATCH <= 32'b0       ;
        else if(csr_wren & (csr_addr == CSR_ADDR_MSCRATCH)) csr_MSCRATCH <= csr_wdata   ;
    end



    // CSR MCAUSE ==========================================


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            csr_MCAUSE <= 32'b0;
        end
        else if(exception_en) begin
            if (funct12==F12_ECALL) begin
                csr_MCAUSE <= MCAUSE_ECALL_M;
            end
            else if (funct12==F12_EBREAK) begin
                csr_MCAUSE <= MCAUSE_BREAK;
            end
        end 
    end

    // CSR FCSR ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            cancel_edge_en_d <= 1'b0;
        end
        else begin
            cancel_edge_en_d <= cancel_edge_en;
        end
        
    end
    assign csr_FCSR[31:8] = 24'b0;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            csr_FCSR[7:0] <= 8'b0;
        end
        else if(cancel_edge_en_d)begin
            csr_FCSR[7:0] <= FCSR_backup;
        end
        else if(csr_wren)begin
            case (csr_addr)
                CSR_ADDR_FFLAGS : csr_FCSR[4:0]     <= csr_wdata[4:0];
                CSR_ADDR_FRM    : csr_FCSR[7:5]     <= csr_wdata[2:0];
                CSR_ADDR_FCSR   : csr_FCSR[7:0]     <= csr_wdata[7:0]; 
                default: ;
            endcase
        end
        else if(csr_FFLAGS_en)begin 
            csr_FCSR[4:0] <= csr_FFLAGS;
        end
    end





endmodule