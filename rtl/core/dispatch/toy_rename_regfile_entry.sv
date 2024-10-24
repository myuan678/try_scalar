module toy_rename_regfile_entry
    import toy_pack::*;
#(
    parameter   int unsigned ARCH_REG_ID    = 31 ,
    parameter   int unsigned MODE           = 0
)
(
    input  logic                                clk                  ,
    input  logic                                rst_n                ,

    input  logic    [PHY_REG_ID_WIDTH-1  :0]    v_reg_rd_allocate_id [INST_DECODE_NUM-1     :0]  ,
    input  logic    [INST_DECODE_NUM-1   :0]    v_reg_rd_en          , 
    input  logic    [4                   :0]    v_reg_rd_index       [INST_DECODE_NUM-1     :0]  ,
    
    input  logic                                cancel_edge_en                                   ,
    input  logic    [PHY_REG_ID_WIDTH-1  :0]    reg_backup_phy_id                                ,           
    output logic    [PHY_REG_ID_WIDTH-1  :0]    reg_phy_id           

);

    generate if((MODE == 0) && (ARCH_REG_ID==0))begin
        assign reg_phy_id = ARCH_REG_ID;
    end
    else begin
        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)begin
                reg_phy_id <= ARCH_REG_ID;
            end
            else if(cancel_edge_en)begin
                reg_phy_id <= reg_backup_phy_id;
            end
            else if(v_reg_rd_en[3] & (v_reg_rd_index[3] == ARCH_REG_ID))begin
                reg_phy_id <= v_reg_rd_allocate_id[3];
            end
            else if(v_reg_rd_en[2] & (v_reg_rd_index[2] == ARCH_REG_ID))begin
                reg_phy_id <= v_reg_rd_allocate_id[2];
            end
            else if(v_reg_rd_en[1] & (v_reg_rd_index[1] == ARCH_REG_ID))begin
                reg_phy_id <= v_reg_rd_allocate_id[1];
            end
            else if(v_reg_rd_en[0] & (v_reg_rd_index[0] == ARCH_REG_ID))begin
                reg_phy_id <= v_reg_rd_allocate_id[0];
            end
        end
    end
    endgenerate









endmodule