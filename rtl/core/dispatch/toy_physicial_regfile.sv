module toy_physicial_regfile 
    import toy_pack::*; 
#(
    parameter   int unsigned MODE          = 0  //0-INT 1-FP
)
(
    input  logic                                clk                     ,
    input  logic                                rst_n                   ,

    input  logic   [EU_NUM-1            :0]     v_wr_en                 ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_wr_reg_index         [EU_NUM-1   :0],
    input  logic   [REG_WIDTH-1         :0]     v_wr_reg_data          [EU_NUM-1   :0],
    
    input  logic   [4                   :0]     v_reg_rd_index          [INST_DECODE_NUM-1:0],
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_rd_allocate_id    [INST_DECODE_NUM-1:0],
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rd_index      [INST_DECODE_NUM-1:0],

    input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_rdy      ,
    input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_zero     , 
    output logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_vld      ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_pre_allocate_id       [INST_DECODE_NUM-1:0],

    output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs1_rdy           , 
    output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs2_rdy           , 
    output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs3_rdy           , 
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs1_index [INST_DECODE_NUM-1:0] ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs2_index [INST_DECODE_NUM-1:0] ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs3_index [INST_DECODE_NUM-1:0] ,
    
    input  logic   [COMMIT_REL_CHANNEL-2:0]     v_phy_release_comb_en   ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_comb_index[COMMIT_REL_CHANNEL-2:0],

    input  logic   [INST_DECODE_NUM-1   :0]     v_phy_release_en        ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_index [INST_DECODE_NUM-1:0] ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_backup_index  [INST_DECODE_NUM-1:0] ,

    input  logic                                cancel_edge_en          ,

    output logic   [REG_WIDTH-1         :0]     v_reg_rs1_data      [INST_DECODE_NUM-1:0] ,
    output logic   [REG_WIDTH-1         :0]     v_reg_rs2_data      [INST_DECODE_NUM-1:0] ,
    output logic   [REG_WIDTH-1         :0]     v_reg_rs3_data      [INST_DECODE_NUM-1:0] 


);
    //##############################################
    // logic  
    //############################################## 
    logic [PHY_REG_NUM-1        :0] v_entry_idle;
    logic [PHY_REG_NUM-1        :0] v_allocate_oh[INST_DECODE_NUM-1:0];
    logic [INST_DECODE_NUM-1    :0] v_allocate_vld;
    logic [PHY_REG_ID_WIDTH-1   :0] v_allocate_id [INST_DECODE_NUM-1:0];
    logic [REG_WIDTH-1          :0] v_reg_phy_data [PHY_REG_NUM-1 :0];
    logic [PHY_REG_NUM-1        :0] v_reg_phy_rdy;
    //##############################################
    // pre allocate 
    //############################################## 
    generate
        for(genvar i=0;i<INST_DECODE_NUM;i=i+1)begin : PHY_REGFILE_
            assign v_reg_rs1_rdy[i]  = v_reg_phy_rdy[v_phy_reg_rs1_index[i]];
            assign v_reg_rs2_rdy[i]  = v_reg_phy_rdy[v_phy_reg_rs2_index[i]];
            assign v_reg_rs3_rdy[i]  = v_reg_phy_rdy[v_phy_reg_rs3_index[i]];
            assign v_reg_rs1_data[i] = v_reg_phy_data[v_phy_reg_rs1_index[i]];
            assign v_reg_rs2_data[i] = v_reg_phy_data[v_phy_reg_rs2_index[i]];
            assign v_reg_rs3_data[i] = v_reg_phy_data[v_phy_reg_rs3_index[i]];

            always_ff @(posedge clk or negedge rst_n) begin 
                if(~rst_n)begin
                    v_pre_allocate_vld[i] <= 1'b0;
                    v_pre_allocate_id[i] <= {PHY_REG_ID_WIDTH{1'b0}};
                end
                else begin
                    v_pre_allocate_vld[i] <= v_allocate_vld[i];
                    v_pre_allocate_id[i] <= v_allocate_id[i];
                end
            end
            if(MODE == 0)begin
                assign v_phy_reg_rd_index[i] = (v_reg_rd_index[i]==0) ? 0 : v_reg_rd_allocate_id[i];
            end
            else begin
                assign v_phy_reg_rd_index[i] = v_reg_rd_allocate_id[i];

            end
        end
    endgenerate

    cmn_list_lead_one #(
        .ENTRY_NUM      (PHY_REG_NUM            ),
        .REQ_NUM        (INST_DECODE_NUM        )
    )u_phy_reg_alloc(
        .v_entry_vld    (v_entry_idle           ),
        .v_free_idx_oh  (v_allocate_oh          ),
        .v_free_idx_bin (v_allocate_id          ),
        .v_free_vld     (v_allocate_vld         )
    );

    //##############################################
    // entry
    //############################################## 
    logic [31:0] sum_cnt [PHY_REG_NUM-1:0];
    generate
        for(genvar j=0;j<PHY_REG_NUM;j=j+1)begin
            toy_physicial_regfile_entry #(
                .PHY_REG_ID         (j                          ),
                .MODE               (MODE                       )
            )
            u_toy_physicial_regfile_entry(
                .clk                (clk                        ),
                .rst_n              (rst_n                      ),
                .reg_phy_rdy        (v_reg_phy_rdy[j]           ),
                .v_phy_release_comb_en(v_phy_release_comb_en    ),
                .v_phy_release_comb_index(v_phy_release_comb_index),
                .v_phy_release_index(v_phy_release_index        ),
                .v_phy_release_en   (v_phy_release_en           ),
                .v_phy_backup_index (v_phy_backup_index         ),
                .cancel_edge_en     (cancel_edge_en             ),
                .v_pre_allocate_rdy (v_pre_allocate_rdy         ),
                .v_pre_allocate_zero(v_pre_allocate_zero        ), 
                .v_pre_allocate_id  (v_pre_allocate_id          ),
                .entry_idle         (v_entry_idle[j]            ),
                .v_wr_reg_data      (v_wr_reg_data              ),
                .v_wr_en            (v_wr_en                    ),
                .v_wr_reg_index     (v_wr_reg_index             ),
                .reg_phy_data       (v_reg_phy_data[j]          )
            );
            if(j==0)begin
                assign sum_cnt[j] = 32'(v_entry_idle[j]==0);
            end
            else begin
                always_comb begin 
                    if(v_entry_idle[j]==0)begin
                        sum_cnt[j] = sum_cnt[j-1] + 1 ;
                    end
                    else begin
                        sum_cnt[j] = sum_cnt[j-1]  ;
                        
                    end
                end
            end

        end
    endgenerate

    logic [31:0] monitor_0;
    logic [31:0] monitor_1;
    assign monitor_0 = sum_cnt[PHY_REG_NUM-1];
    assign monitor_1 = PHY_REG_NUM - sum_cnt[PHY_REG_NUM-1];
    
endmodule