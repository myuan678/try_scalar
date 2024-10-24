
module toy_regfile 
    import toy_pack::*;
    #(
        parameter integer unsigned MODE = 0  // 0-INT 1-FLOAT
    )(
        input  logic                                clk                     ,
        input  logic                                rst_n                   ,

        output logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_vld      ,
        input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_rdy      ,
        input  logic   [INST_DECODE_NUM-1   :0]     v_pre_allocate_zero     ,     
        output logic   [PHY_REG_ID_WIDTH-1  :0]     v_pre_allocate_id       [INST_DECODE_NUM-1:0],
        output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rd_index      [INST_DECODE_NUM-1:0],
    
        input  logic                                cancel_edge_en          ,
        input  logic   [COMMIT_REL_CHANNEL-1:0]     v_commit_en             ,
        input  commit_pkg                           v_commit_pld            [COMMIT_REL_CHANNEL-1:0],

        input  logic   [INST_DECODE_NUM-1   :0]     v_reg_rd_en             , //check pre alloc,in order hazard
        input  logic   [4                   :0]     v_reg_rd_index          [INST_DECODE_NUM-1:0],
        input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_rd_allocate_id    [INST_DECODE_NUM-1:0],
        input  logic   [4                   :0]     v_reg_rs1_index         [INST_DECODE_NUM-1:0] ,
        input  logic   [4                   :0]     v_reg_rs2_index         [INST_DECODE_NUM-1:0] ,
        input  logic   [4                   :0]     v_reg_rs3_index         [INST_DECODE_NUM-1:0] ,
        output logic   [REG_WIDTH-1         :0]     v_reg_rs1_data          [INST_DECODE_NUM-1:0] ,
        output logic   [REG_WIDTH-1         :0]     v_reg_rs2_data          [INST_DECODE_NUM-1:0] ,
        output logic   [REG_WIDTH-1         :0]     v_reg_rs3_data          [INST_DECODE_NUM-1:0] ,
        output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs1_rdy           , 
        output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs2_rdy           , 
        output logic   [INST_DECODE_NUM-1   :0]     v_reg_rs3_rdy           , 
        input  logic   [EU_NUM-1            :0]     v_wr_en                 ,
        input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_wr_reg_index          [EU_NUM-1   :0],
        input  logic   [REG_WIDTH-1         :0]     v_wr_reg_data           [EU_NUM-1   :0]
        
    );
    //##############################################
    // logic 
    //############################################## 
    logic   [INST_DECODE_NUM-1   :0]     v_phy_rd_en        ;
    logic   [COMMIT_REL_CHANNEL-1:0]     v_phy_release_en   ;
    logic   [COMMIT_REL_CHANNEL-2:0]     v_phy_release_comb_en;
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_comb_index[COMMIT_REL_CHANNEL-2:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs1_index [INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs2_index [INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs3_index [INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_index [INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_backup_index  [INST_DECODE_NUM-1:0];
    logic   [4                   :0]     v_phy_rd_index      [INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_rd_allocate_id[INST_DECODE_NUM-1:0];
    logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_backup_phy_id [ARCH_ENTRY_NUM-1 :0];
    //##############################################
    // rename table
    //############################################## 
    toy_rename_regfile #(
        .MODE                (MODE                      )
    )u_rename_reg_file(
        .clk                 (clk                       ),
        .rst_n               (rst_n                     ),
        .v_reg_rd_allocate_id(v_reg_rd_allocate_id      ),
        .v_reg_rd_en         (v_reg_rd_en               ),
        .v_reg_rd_index      (v_reg_rd_index            ),
        .v_phy_rd_en         (v_phy_rd_en               ),
        .v_phy_rd_index      (v_phy_rd_index            ),
        .v_phy_rd_allocate_id(v_phy_rd_allocate_id      ),
        .cancel_edge_en      (cancel_edge_en            ),
        .v_reg_backup_phy_id (v_reg_backup_phy_id       ),
        .v_reg_rs1_index     (v_reg_rs1_index           ),
        .v_reg_rs2_index     (v_reg_rs2_index           ),
        .v_reg_rs3_index     (v_reg_rs3_index           ),
        .v_phy_reg_rs1_index (v_phy_reg_rs1_index       ),
        .v_phy_reg_rs2_index (v_phy_reg_rs2_index       ),
        .v_phy_reg_rs3_index (v_phy_reg_rs3_index       )
        // .v_phy_release_index (v_phy_release_index       )
    );

    //##############################################
    // backup reg file
    //############################################## 
    toy_backup_rename_regfile #(
        .MODE               (MODE                               )
    )u_toy_backup_rename_regfile(
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .v_reg_backup_phy_id        (v_reg_backup_phy_id        ),
        .v_commit_en                (v_commit_en                ),
        .v_commit_pld               (v_commit_pld               ),
        .v_phy_release_comb_en      (v_phy_release_comb_en      ),
        .v_phy_release_comb_index   (v_phy_release_comb_index   ),
        .v_phy_release_en           (v_phy_release_en           ),
        .v_phy_release_index        (v_phy_release_index        ),
        .v_phy_backup_index         (v_phy_backup_index         )
    );

    //##############################################
    // phy reg file
    //############################################## 
    toy_physicial_regfile #(
        .MODE               (MODE                       )
    )u_toy_physicial_regfile(

        .clk                    (clk                    ),
        .rst_n                  (rst_n                  ),
        .v_wr_en                (v_wr_en                ),
        .v_wr_reg_index         (v_wr_reg_index         ),
        .v_wr_reg_data          (v_wr_reg_data          ),
        .v_reg_rd_index         (v_reg_rd_index         ),
        .v_reg_rd_allocate_id   (v_phy_rd_allocate_id   ),
        .v_phy_reg_rd_index     (v_phy_reg_rd_index     ),
        .v_pre_allocate_rdy     (v_pre_allocate_rdy     ),
        .v_pre_allocate_zero    (v_pre_allocate_zero    ),
        .v_pre_allocate_vld     (v_pre_allocate_vld     ),
        .v_pre_allocate_id      (v_pre_allocate_id      ),
        .v_reg_rs1_rdy          (v_reg_rs1_rdy          ),
        .v_reg_rs2_rdy          (v_reg_rs2_rdy          ),
        .v_reg_rs3_rdy          (v_reg_rs3_rdy          ),
        .v_phy_reg_rs1_index    (v_phy_reg_rs1_index    ),
        .v_phy_reg_rs2_index    (v_phy_reg_rs2_index    ),
        .v_phy_reg_rs3_index    (v_phy_reg_rs3_index    ),
        .v_phy_release_comb_en  (v_phy_release_comb_en  ),
        .v_phy_release_comb_index(v_phy_release_comb_index),
        .v_phy_release_en       (v_phy_release_en       ),
        .v_phy_release_index    (v_phy_release_index    ),
        .v_phy_backup_index     (v_phy_backup_index     ),
        .cancel_edge_en         (cancel_edge_en         ),
        .v_reg_rs1_data         (v_reg_rs1_data         ),
        .v_reg_rs2_data         (v_reg_rs2_data         ),
        .v_reg_rs3_data         (v_reg_rs3_data         )
    );





endmodule



