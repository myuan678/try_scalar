module toy_bpu_btfifo
  import toy_pack::*;
  #(
    localparam integer unsigned PTR_WIDTH = $clog2(BTFIFO_DEPTH)
  )(
    input logic        clk,
    input logic        rst_n,

    // bpdec ==============================
    input logic        bpdec_bp2_vld,
    input logic        bpdec_bp2_chgflw,
    input bpu_pkg      bpdec_bp2_chgflw_pld,

    // filter =============================
    input  logic       filter_rdy,
    output logic       filter_vld,
    output bpu_pkg     filter_pld,

    // fe controller ======================
    input logic        fe_ctrl_flush
  );

  bpu_pkg                    fifo_entry  [BTFIFO_DEPTH-1:0];
  logic   [BTFIFO_DEPTH-1:0] entry_en;
  logic   [PTR_WIDTH:0]      rd_ptr;
  logic   [PTR_WIDTH:0]      en_ptr;
  logic                      rden;
  logic                      bp2_wren;


  // for interface
  assign filter_vld       = entry_en[rd_ptr[PTR_WIDTH-1:0]];
  assign filter_pld       = fifo_entry[rd_ptr[PTR_WIDTH-1:0]];

  // for pointer
  assign rden             = filter_vld && filter_rdy;
  assign bp2_wren         = bpdec_bp2_vld && ~bpdec_bp2_chgflw && ~fe_ctrl_flush;


  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   rd_ptr <= {PTR_WIDTH{1'b0}};
    else if(fe_ctrl_flush)        rd_ptr <= {PTR_WIDTH{1'b0}};
    else if(rden)                 rd_ptr <= rd_ptr + 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   en_ptr <= {PTR_WIDTH{1'b0}};
    else if(fe_ctrl_flush)        en_ptr <= {PTR_WIDTH{1'b0}};
    else if(bp2_wren)             en_ptr <= en_ptr + 1'b1;
  end

  // for entry and enable
  generate
    for (genvar i = 0; i < BTFIFO_DEPTH; i=i+1) begin: GEN_ENABLE
      always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                        entry_en[i] <= 1'b0;
        else if(fe_ctrl_flush)                             entry_en[i] <= 1'b0;
        else if((bp2_wren) && en_ptr[PTR_WIDTH-1:0]==i)    entry_en[i] <= 1'b1;
        else if(rden && rd_ptr[PTR_WIDTH-1:0]==i)          entry_en[i] <= 1'b0;
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < BTFIFO_DEPTH; i=i+1) begin: GEN_ENTRY
      always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                        fifo_entry[i] <= 1'b0;
        else if((bp2_wren) && en_ptr[PTR_WIDTH-1:0]==i)    fifo_entry[i] <= bpdec_bp2_chgflw_pld;
      end
    end
  endgenerate

endmodule