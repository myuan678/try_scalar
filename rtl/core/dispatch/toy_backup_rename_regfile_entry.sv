module toy_backup_rename_regfile_entry
    import toy_pack::*;
#(
    parameter   int unsigned ARCH_REG_ID    = 31 ,
    parameter   int unsigned MODE           = 0
)
(
    input  logic                                    clk                  ,
    input  logic                                    rst_n                ,

    input  logic    [COMMIT_REL_CHANNEL-1   :0]     v_commit_en          , 
    input  commit_pkg                               v_commit_pld         [COMMIT_REL_CHANNEL-1:0]  ,
    
    output logic    [PHY_REG_ID_WIDTH-1     :0]     reg_phy_id            //rel entry

);
    logic    [COMMIT_REL_CHANNEL-1   :0]     rd_en                ;

    //==============================================
    // fp int mode rd sel
    //==============================================
    generate
        for(genvar i=0;i<COMMIT_REL_CHANNEL;i=i+1)begin
            if(MODE==0)begin
                assign rd_en[i] = v_commit_pld[i].rd_en;
            end
            else begin
                assign rd_en[i] = v_commit_pld[i].fp_rd_en;
                
            end
        end
    endgenerate


    //==============================================
    // update arch reg file
    //==============================================
    generate if((MODE == 0) && (ARCH_REG_ID==0))begin
        assign reg_phy_id = ARCH_REG_ID;
    end
    else begin
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)begin
                reg_phy_id <= ARCH_REG_ID;
            end

            else if(v_commit_en[3] & rd_en[3] & (v_commit_pld[3].arch_reg_index == ARCH_REG_ID))begin
                reg_phy_id <= v_commit_pld[3].phy_reg_index;
            end
            else if(v_commit_en[2] & rd_en[2] & (v_commit_pld[2].arch_reg_index == ARCH_REG_ID))begin
                reg_phy_id <= v_commit_pld[2].phy_reg_index;
            end
            else if(v_commit_en[1] & rd_en[1] & (v_commit_pld[1].arch_reg_index == ARCH_REG_ID))begin
                reg_phy_id <= v_commit_pld[1].phy_reg_index;
            end
            else if(v_commit_en[0] & rd_en[0] & (v_commit_pld[0].arch_reg_index == ARCH_REG_ID))begin
                reg_phy_id <= v_commit_pld[0].phy_reg_index;
            end

        end
    end
    endgenerate









endmodule