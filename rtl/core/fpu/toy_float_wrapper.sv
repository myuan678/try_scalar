

module toy_float_wrapper
    import toy_pack::*;
    (
        input  logic                      clk                 ,
        input  logic                      rst_n               ,

        input  logic                      instruction_vld     ,
        output logic                      instruction_rdy     ,
        input  eu_pkg                     instruction_pld     ,
        input  logic [31:0]               csr_FCSR            ,
        output logic                      csr_FFLAGS_en       ,
        output logic [4:0]                csr_FFLAGS          ,
        //commit 
        output commit_pkg                 fp_commit_pld       ,
        // reg access
        output logic [PHY_REG_ID_WIDTH-1:0]reg_index          ,
        output logic                      reg_wr_en           ,
        output logic [REG_WIDTH-1:0]      reg_val             ,
        output logic                      fp_reg_wr_en        ,
        output logic [INST_IDX_WIDTH-1:0] reg_inst_idx        ,
        output logic                      inst_commit_en      
    
    );
    //==============================
    // logic
    //==============================
    eu_pkg                          multi_cycle_pld         ;
    commit_pkg                      fp_commit_pld_multi     ; 
    commit_pkg                      fp_commit_pld_reg       ;

    logic                           instruction_en          ;
    logic                           instruction_en_multi_o  ;
    logic                           instruction_en_o_d      ;
    logic                           instruction_en_o        ;
    logic                           instruction_en_reg      ;
    logic                           csr_FFLAGS_en_multi     ;
    logic                           reg_wr_en_multi         ; 
    logic                           fp_reg_wr_en_multi      ; 
    logic                           inst_commit_en_multi    ; 
    logic                           csr_FFLAGS_en_reg       ;
    logic                           reg_wr_en_reg           ;
    logic                           fp_reg_wr_en_reg        ;
    logic                           inst_commit_en_reg      ;

    logic [$clog2(FP_STAGES)    :0] multi_cycle_cnt         ;
    logic [31                   :0] csr_FCSR_reg            ;
    logic [4                    :0] csr_FFLAGS_multi        ; 
    logic [PHY_REG_ID_WIDTH-1   :0] reg_index_multi         ; 
    logic [REG_WIDTH-1          :0] reg_val_multi           ; 
    logic [INST_IDX_WIDTH-1     :0] reg_inst_idx_multi      ; 
    logic [4                    :0] csr_FFLAGS_reg          ;
    logic [PHY_REG_ID_WIDTH-1   :0] reg_index_reg           ;
    logic [REG_WIDTH-1          :0] reg_val_reg             ;
    logic [INST_IDX_WIDTH-1     :0] reg_inst_idx_reg        ;

    //==============================
    // multi cycle ready
    //==============================

    assign instruction_en = instruction_vld & instruction_rdy;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            multi_cycle_cnt <= FP_STAGES;
        end
        else if(instruction_en)begin
            multi_cycle_cnt <= 0;
        end
        else if(multi_cycle_cnt<FP_STAGES)begin
            multi_cycle_cnt <= multi_cycle_cnt + 1;
        end
    end
    assign instruction_rdy = (multi_cycle_cnt == FP_STAGES);

    assign instruction_en_multi_o = (multi_cycle_cnt == (FP_STAGES-1));
    //==============================
    // input reg logic
    //==============================
    assign instruction_en_reg = (multi_cycle_cnt!=FP_STAGES);
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            instruction_en_o_d <= 0;
            instruction_en_o <= 0;
        end
        else begin
            instruction_en_o_d <= instruction_en_multi_o;
            instruction_en_o <= instruction_en_o_d;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            multi_cycle_pld <= {$bits(eu_pkg){1'b0}};
            csr_FCSR_reg <= 0;
        end
        else if(instruction_en)begin
            multi_cycle_pld <= instruction_pld;
            csr_FCSR_reg <= csr_FCSR;
        end
    end
    //==============================
    // output reg logic
    //==============================
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin    
            csr_FFLAGS_en_multi   <= 0;    
            csr_FFLAGS_multi      <= 0;    
            fp_commit_pld_multi   <= {$bits(commit_pkg){1'b0}};    
            reg_index_multi       <= 0;    
            reg_wr_en_multi       <= 0;    
            reg_val_multi         <= 0;    
            fp_reg_wr_en_multi    <= 0;    
            reg_inst_idx_multi    <= 0;    
            inst_commit_en_multi  <= 0;    
        end
        else if(instruction_en_multi_o)begin
            csr_FFLAGS_en_multi       <= csr_FFLAGS_en_reg  ;    
            csr_FFLAGS_multi          <= csr_FFLAGS_reg     ;    
            fp_commit_pld_multi       <= fp_commit_pld_reg  ;    
            reg_index_multi           <= reg_index_reg      ;    
            reg_wr_en_multi           <= reg_wr_en_reg      ;    
            reg_val_multi             <= reg_val_reg        ;    
            fp_reg_wr_en_multi        <= fp_reg_wr_en_reg   ;    
            reg_inst_idx_multi        <= reg_inst_idx_reg   ;    
            inst_commit_en_multi      <= inst_commit_en_reg ;    
        end
    end

    assign csr_FFLAGS_en = csr_FFLAGS_en_multi & instruction_en_o;
    assign reg_wr_en = reg_wr_en_multi & instruction_en_o;
    assign fp_reg_wr_en = fp_reg_wr_en_multi & instruction_en_o;
    assign inst_commit_en = inst_commit_en_multi & instruction_en_o;
    
    assign csr_FFLAGS     = csr_FFLAGS_multi         ;
    assign fp_commit_pld  = fp_commit_pld_multi      ;
    assign reg_index      = reg_index_multi          ;
    assign reg_val        = reg_val_multi            ;
    assign reg_inst_idx   = reg_inst_idx_multi       ;
    //==============================
    // fp eu
    //==============================
    toy_float u_toy_float(

        .clk                    (clk                    ),
        .rst_n                  (rst_n                  ),
        .instruction_vld        (instruction_en_reg     ),
        .instruction_rdy        (                       ),
        .instruction_pld        (multi_cycle_pld        ),
        .csr_FCSR               (csr_FCSR_reg           ),
        .csr_FFLAGS_en          (csr_FFLAGS_en_reg      ),
        .csr_FFLAGS             (csr_FFLAGS_reg         ),
        .fp_commit_pld          (fp_commit_pld_reg      ),
        .reg_index              (reg_index_reg          ),
        .reg_wr_en              (reg_wr_en_reg          ),
        .reg_val                (reg_val_reg            ),
        .fp_reg_wr_en           (fp_reg_wr_en_reg       ),
        .reg_inst_idx           (reg_inst_idx_reg       ),
        .inst_commit_en         (inst_commit_en_reg     )
    );


endmodule