module toy_rename_regfile
    import toy_pack::*;
#(
    parameter   int unsigned MODE          = 0  //0-INT 1-FP
)
(
    input  logic                                clk                     ,
    input  logic                                rst_n                   ,

    input  logic   [INST_DECODE_NUM-1   :0]     v_reg_rd_en             , //check pre alloc,in order hazard
    input  logic   [4                   :0]     v_reg_rd_index          [INST_DECODE_NUM-1:0],
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_rd_allocate_id    [INST_DECODE_NUM-1:0],
    output logic   [INST_DECODE_NUM-1   :0]     v_phy_rd_en             , //check pre alloc,in order hazard
    output logic   [4                   :0]     v_phy_rd_index          [INST_DECODE_NUM-1:0],
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_rd_allocate_id    [INST_DECODE_NUM-1:0],

    input  logic                                cancel_edge_en          ,
    input  logic   [PHY_REG_ID_WIDTH-1  :0]     v_reg_backup_phy_id     [ARCH_ENTRY_NUM-1 :0],

    input  logic   [4                   :0]     v_reg_rs1_index         [INST_DECODE_NUM-1:0] ,
    input  logic   [4                   :0]     v_reg_rs2_index         [INST_DECODE_NUM-1:0] ,
    input  logic   [4                   :0]     v_reg_rs3_index         [INST_DECODE_NUM-1:0] ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs1_index     [INST_DECODE_NUM-1:0] ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs2_index     [INST_DECODE_NUM-1:0] ,
    output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_reg_rs3_index     [INST_DECODE_NUM-1:0] 
    // output logic   [PHY_REG_ID_WIDTH-1  :0]     v_phy_release_index     [INST_DECODE_NUM-1:0] 

);
    //##############################################
    // logic
    //############################################## 
    logic [PHY_REG_ID_WIDTH-1:0] v_reg_phy_id [ARCH_ENTRY_NUM-1:0];
    logic                        cancel_edge_en_d;

    assign v_phy_rd_en          = v_reg_rd_en;
    assign v_phy_rd_index       = v_reg_rd_index;
    assign v_phy_rd_allocate_id = v_reg_rd_allocate_id;
    //##############################################
    // entry
    //############################################## 

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            cancel_edge_en_d <= 1'b0;
        end
        else begin
            cancel_edge_en_d <= cancel_edge_en;
        end
    end

    generate
        for(genvar j=0;j<ARCH_ENTRY_NUM;j=j+1)begin:RENAME_FILE_
            toy_rename_regfile_entry #(
                .ARCH_REG_ID(j),
                .MODE       (MODE)
            )u_toy_rename_regfile_entry(
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .v_reg_rd_allocate_id   (v_reg_rd_allocate_id           ),
                .v_reg_rd_en            (v_reg_rd_en                    ),
                .v_reg_rd_index         (v_reg_rd_index                 ),
                .cancel_edge_en         (cancel_edge_en_d               ),
                .reg_backup_phy_id      (v_reg_backup_phy_id[j]         ),
                .reg_phy_id             (v_reg_phy_id[j]                )
            );

        end       
    //##############################################
    // look up id
    //############################################## 
        for (genvar k = 0;k < INST_DECODE_NUM;k = k + 1 ) begin:PHY_REG_
            assign v_phy_reg_rs1_index[k] = v_reg_phy_id[v_reg_rs1_index[k]];
            assign v_phy_reg_rs2_index[k] = v_reg_phy_id[v_reg_rs2_index[k]];
            assign v_phy_reg_rs3_index[k] = v_reg_phy_id[v_reg_rs3_index[k]];
            // assign v_phy_release_index[k] = v_reg_phy_id[v_reg_rd_index[k]];
        end


    endgenerate








endmodule