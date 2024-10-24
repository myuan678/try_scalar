module toy_physicial_regfile_entry
    import toy_pack::*; 
#(
    parameter   int unsigned PHY_REG_ID    = 95,
    parameter   int unsigned MODE          = 0  //0-INT 1-FP
)
(
    input  logic                                clk                     ,
    input  logic                                rst_n                   ,

    output logic                                reg_phy_rdy             ,

    input  logic   [COMMIT_REL_CHANNEL-2:0]     v_phy_release_comb_en   ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_comb_index[COMMIT_REL_CHANNEL-2:0],

    input  logic   [INST_DECODE_NUM-1   :0]     v_phy_release_en        ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_index     [INST_DECODE_NUM-1:0],
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_backup_index      [INST_DECODE_NUM-1:0],

    input  logic                                cancel_edge_en          ,

    input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_rdy      ,
    input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_zero     , 
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_pre_allocate_id       [INST_DECODE_NUM-1:0],

    output logic                                entry_idle              ,
    
    input  logic   [EU_NUM-1            :0]     v_wr_en                 ,                         
    input  logic   [REG_WIDTH-1         :0]     v_wr_reg_data           [EU_NUM-1           :0],
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_wr_reg_index          [EU_NUM-1           :0],
    
    output logic   [REG_WIDTH-1         :0]     reg_phy_data            

);
    
    //##############################################
    // logic
    //############################################## 
    logic                          entry_commit     ;
    logic                          registers_wren   ;
    logic                          entry_release_en ;
    logic                          entry_backup     ;
    logic                          entry_release_en_reg ;
    logic [REG_WIDTH-1         :0] registers_wrdata ;
    logic [EU_NUM-1            :0] v_registers_wren ;
    logic [INST_DECODE_NUM-1   :0] v_release_en     ;
    logic [INST_DECODE_NUM-1   :0] v_backup_en      ;
    logic [INST_DECODE_NUM-1   :0] v_alloc_en       ;
    genvar i;
    //##############################################
    // wr data
    //############################################## 
    assign entry_idle = entry_commit && entry_release_en;

    assign reg_phy_rdy      = entry_commit;
    assign registers_wren   = |v_registers_wren;

    assign registers_wrdata =   v_registers_wren[0] ? v_wr_reg_data[0]:
                                v_registers_wren[1] ? v_wr_reg_data[1]:
                                v_registers_wren[2] ? v_wr_reg_data[2]:
                                v_registers_wren[3] ? v_wr_reg_data[3]:
                                v_registers_wren[4] ? v_wr_reg_data[4]:
                                v_registers_wren[5] ? v_wr_reg_data[5]:
                                v_registers_wren[6] ? v_wr_reg_data[6]:
                                v_registers_wren[7] ? v_wr_reg_data[7]:
                                v_registers_wren[8] ? v_wr_reg_data[8]:
                                v_registers_wren[9] ? v_wr_reg_data[9]:
                                0;

    generate
        for (genvar j=0;j<EU_NUM;j=j+1)begin
            assign v_registers_wren[j]    =  v_wr_en[j] & (PHY_REG_ID==v_wr_reg_index[j]);
        end
        for (i=0;i<INST_DECODE_NUM;i=i+1)begin
            if(i<INST_DECODE_NUM-1)begin
                assign v_release_en[i] = (v_phy_release_en[i] & (v_phy_release_index[i]==PHY_REG_ID)) || 
                                         (v_phy_release_comb_en[i] & (v_phy_release_comb_index[i] == PHY_REG_ID)) ;
            end
            else begin
                assign v_release_en[i] = v_phy_release_en[i] & (v_phy_release_index[i]==PHY_REG_ID);
            end
        end
        for (genvar k=0;k<COMMIT_REL_CHANNEL;k=k+1)begin
            // if(k<COMMIT_REL_CHANNEL-1)begin
            //     assign v_backup_en[k]  = v_phy_release_en[k] & ~v_phy_release_comb_en[k] & (v_phy_backup_index[k]==PHY_REG_ID);
            // end
            // else begin
            assign v_backup_en[k]  = v_phy_release_en[k] & (v_phy_backup_index[k]==PHY_REG_ID);
            // end
        end
    endgenerate                        
    //##############################################
    // pre allocate 
    //############################################## 
    generate
        if(MODE == 0)begin
            for (i=0;i<INST_DECODE_NUM;i=i+1)begin
                assign v_alloc_en[i] = v_pre_allocate_rdy[i] & (v_pre_allocate_id[i]==PHY_REG_ID) & (~v_pre_allocate_zero[i]);
            end
        end
        else begin
            for (i=0;i<INST_DECODE_NUM;i=i+1)begin
                assign v_alloc_en[i] = v_pre_allocate_rdy[i] & (v_pre_allocate_id[i]==PHY_REG_ID);
            end  
        end
    endgenerate
    //##############################################
    // entry logic
    //############################################## 
    generate 
        if((PHY_REG_ID==0) && (MODE==0))begin //generate int 0
            assign reg_phy_data    =  {REG_WIDTH{1'b0}};
            assign entry_release_en= 1'b0;
            assign entry_commit    = 1'b1;
            assign entry_backup    = 1'b1;
        end
        else begin // generate 0-31 reg
            // 0-31 idle = 0 ,32-95 idle = 1
            always_comb begin 
                if(|v_alloc_en)begin
                    entry_release_en = 1'b0;
                end
                else begin
                    entry_release_en = entry_release_en_reg;
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    entry_release_en_reg <= (PHY_REG_ID>=ARCH_ENTRY_NUM);
                end
                else if(|v_release_en)begin
                    entry_release_en_reg <= 1'b1;
                end
                else if(cancel_edge_en & ~entry_backup & ~|v_backup_en)begin
                    entry_release_en_reg <= 1'b1;
                end
                else if(|v_alloc_en)begin
                    entry_release_en_reg <= 1'b0;
                end
            end
            // back up 
            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    entry_backup <= (PHY_REG_ID<ARCH_ENTRY_NUM);
                end
                else if(|v_release_en)begin
                    entry_backup <= 1'b0;
                end
                else if(|v_backup_en)begin
                    entry_backup <= 1'b1;
                end
            end       


            // commit
            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    entry_commit <= 1'b1;
                end
                else if(cancel_edge_en & ~entry_backup & ~|v_backup_en)begin
                    entry_commit <= 1'b1;
                end
                else if(registers_wren)begin
                    entry_commit <= 1'b1;
                end
                else if(|v_alloc_en)begin
                    entry_commit <= 1'b0;
                end
            end

            // data
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    reg_phy_data <= {REG_WIDTH{1'b0}};
                end
                else if(registers_wren)begin
                    reg_phy_data <= registers_wrdata;
                end
            end
        end
    endgenerate

    

endmodule