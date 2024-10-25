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

  bpu_pkg                    fifo_entry   [BTFIFO_DEPTH-1:0];
  bpu_pkg                    enq_reg;
  logic                      enq_reg_vld;
  bpu_pkg                    deq_reg;
  logic                      deq_reg_vld;

  logic   [PTR_WIDTH:0]      rd_ptr;
  logic   [PTR_WIDTH:0]      wr_ptr;
  logic                      rden;
  logic                      wren;

  bpu_pkg                    deq_reg_comb;
  logic                      enq_wren;
  logic                      enq_rden;
  logic                      deq_wren;
  logic                      deq_bpdec_wren;
  logic                      deq_enq_wren;
  logic                      deq_fifo_wren;
  logic                      deq_rden;
  logic                      fifo_wren;
  logic                      fifo_rden;


  //=====================================================================
  // Interface
  //=====================================================================
  assign filter_vld       = deq_reg_vld;
  assign filter_pld       = deq_reg;
  

  assign rden             = filter_vld && filter_rdy;
  assign wren             = bpdec_bp2_vld && ~bpdec_bp2_chgflw && ~fe_ctrl_flush;

  //=====================================================================
  // Dequeue register
  //=====================================================================
  assign deq_bpdec_wren = wren;
  assign deq_enq_wren   = enq_reg_vld;
  assign deq_fifo_wren  = (rd_ptr != wr_ptr);
  assign deq_rden       = rden;

  always_comb begin
    if (deq_reg_vld && ~rden)    deq_wren = 1'b0;         // reg full
    else if (deq_fifo_wren)      deq_wren = 1'b1;         // fifo not empty
    else if (deq_enq_wren)       deq_wren = 1'b1;         // enq has things
    else if (deq_bpdec_wren)     deq_wren = 1'b1;         // input coming
    else                         deq_wren = 1'b0;         
  end

  always_comb begin
    if (deq_fifo_wren)            deq_reg_comb = fifo_entry[rd_ptr[PTR_WIDTH-1:0]];
    else if (deq_enq_wren)        deq_reg_comb = enq_reg;
    else if (deq_bpdec_wren)      deq_reg_comb = bpdec_bp2_chgflw_pld;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   deq_reg_vld <= 1'b0;
    else if(fe_ctrl_flush)        deq_reg_vld <= 1'b0;
    else if(deq_wren)             deq_reg_vld <= 1'b1;
    else if(deq_rden)             deq_reg_vld <= 1'b0;
  end


  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   deq_reg <= {($bits(bpu_pkg)){1'b0}};
    else if(deq_wren)             deq_reg <= deq_reg_comb;
  end


  //=====================================================================
  // FIFO
  //=====================================================================
  assign fifo_wren = ((rd_ptr != wr_ptr) || ((rd_ptr == wr_ptr) && deq_reg_vld && ~rden)) && enq_reg_vld; // 1.fifo empty and deq not wren; 2. fifo not empty
  assign fifo_rden = (~deq_reg_vld | rden) && (rd_ptr != wr_ptr);                                         // not empty and need read

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   rd_ptr <= {PTR_WIDTH{1'b0}};
    else if(fe_ctrl_flush)        rd_ptr <= {PTR_WIDTH{1'b0}};
    else if(fifo_rden)            rd_ptr <= rd_ptr + 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)                   wr_ptr <= {PTR_WIDTH{1'b0}};
    else if(fe_ctrl_flush)        wr_ptr <= {PTR_WIDTH{1'b0}};
    else if(fifo_wren)            wr_ptr <= wr_ptr + 1'b1;
  end

  generate
    for (genvar i = 0; i < BTFIFO_DEPTH; i=i+1) begin: GEN_ENTRY
      always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)                                         fifo_entry[i] <= 1'b0;
        else if(fifo_wren && wr_ptr[PTR_WIDTH-1:0]==i)      fifo_entry[i] <= enq_reg;
      end
    end
  endgenerate


  //=====================================================================
  // Enqueue register
  //=====================================================================
  assign enq_wren = ((deq_reg_vld && ~rden) || enq_reg_vld || (rd_ptr != wr_ptr)) && wren;                              // not write: 1. deq stall; 2. enq_reg has things; 3. fifo has things
  assign enq_rden = (~deq_reg_vld || (deq_reg_vld && rden) || ({~rd_ptr[PTR_WIDTH], rd_ptr[PTR_WIDTH-1:0]} != wr_ptr)); // read: 1. deq can accept; 2. fifo not full

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)             enq_reg_vld <= 1'b0;
    else if(fe_ctrl_flush)  enq_reg_vld <= 1'b0;
    else if(enq_wren)       enq_reg_vld <= 1'b1;
    else if(enq_rden)       enq_reg_vld <= 1'b0;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)             enq_reg <= {($bits(bpu_pkg)){1'b0}};
    else if(enq_wren)       enq_reg <= bpdec_bp2_chgflw_pld;
  end



endmodule