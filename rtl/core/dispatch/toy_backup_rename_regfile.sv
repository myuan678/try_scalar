module toy_backup_rename_regfile
    import toy_pack::*;
#(
    parameter   int unsigned MODE          = 0  //0-INT 1-FP
)
(
    input  logic                                clk                     ,
    input  logic                                rst_n                   ,

    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_backup_phy_id     [ARCH_ENTRY_NUM-1 :0],

    input  logic   [COMMIT_REL_CHANNEL-1:0]     v_commit_en             ,
    input  commit_pkg                           v_commit_pld            [COMMIT_REL_CHANNEL-1:0],
    
    output logic   [COMMIT_REL_CHANNEL-2:0]     v_phy_release_comb_en   ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_comb_index[COMMIT_REL_CHANNEL-2:0],

    output logic   [COMMIT_REL_CHANNEL-1:0]     v_phy_release_en        ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_index     [COMMIT_REL_CHANNEL-1:0] ,

    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_backup_index      [COMMIT_REL_CHANNEL-1:0] 
);
    //##############################################
    // logic
    //############################################## 
    logic [PHY_REG_ID_WIDTH-1:0] v_reg_phy_id [ARCH_ENTRY_NUM-1:0];

    assign v_reg_backup_phy_id  = v_reg_phy_id;
    //##############################################
    // entry
    //############################################## 
    generate
        for(genvar j=0;j<ARCH_ENTRY_NUM;j=j+1)begin:RENAME_FILE_
            toy_backup_rename_regfile_entry #(
                .ARCH_REG_ID(j),
                .MODE       (MODE)
            )toy_backup_rename_regfile_entry(
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .v_commit_en            (v_commit_en                    ),
                .v_commit_pld           (v_commit_pld                   ),
                .reg_phy_id             (v_reg_phy_id[j]                )
            );

        end       
    //##############################################
    // look up id
    //############################################## 

        assign v_phy_release_comb_en[0] =   v_phy_release_en[0] && 
                                           (((v_commit_pld[0].arch_reg_index == v_commit_pld[1].arch_reg_index) && (v_phy_release_en[1])) || 
                                            ((v_commit_pld[0].arch_reg_index == v_commit_pld[2].arch_reg_index) && (v_phy_release_en[2])) || 
                                            ((v_commit_pld[0].arch_reg_index == v_commit_pld[3].arch_reg_index) && (v_phy_release_en[3])))   ;
        assign v_phy_release_comb_en[1] =   v_phy_release_en[1] && 
                                           (((v_commit_pld[1].arch_reg_index == v_commit_pld[2].arch_reg_index) && (v_phy_release_en[2])) || 
                                            ((v_commit_pld[1].arch_reg_index == v_commit_pld[3].arch_reg_index) && (v_phy_release_en[3])))   ;
        assign v_phy_release_comb_en[2] =   v_phy_release_en[2] && 
                                           (((v_commit_pld[2].arch_reg_index == v_commit_pld[3].arch_reg_index) && (v_phy_release_en[3])))   ;

        for (genvar k = 0;k < COMMIT_REL_CHANNEL;k = k + 1 ) begin:PHY_REG_
            assign v_phy_backup_index[k] = v_commit_pld[k].phy_reg_index;
            assign v_phy_release_index[k] = v_reg_phy_id[v_commit_pld[k].arch_reg_index];
            if(MODE==0)begin
                assign v_phy_release_en[k] = v_commit_en[k] & v_commit_pld[k].rd_en;
            end
            else begin
                assign v_phy_release_en[k] = v_commit_en[k] & v_commit_pld[k].fp_rd_en;
            end
            if(k<3)begin
                assign v_phy_release_comb_index[k] = v_commit_pld[k].phy_reg_index;
            end
        end


    endgenerate








endmodule