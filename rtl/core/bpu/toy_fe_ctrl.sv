module toy_fe_ctrl
   import toy_pack::*;
   (
      input logic                                     clk,
      input logic                                     rst_n,

      // icache ==============================================
      output logic                                    icache_req_vld,
      output logic [ROB_ENTRY_ID_WIDTH-1:0]           icache_req_entry_id,
      output logic [ADDR_WIDTH-1:0]                   icache_req_addr,
      input  logic                                    icache_req_rdy,

      // l0btb ===============================================
      output logic                                    l0btb_pred_vld,
      output logic [ADDR_WIDTH-1:0]                   l0btb_pred_pc,

      output logic                                    l0btb_chgflw_vld_o,
      output bpu_pkg                                  l0btb_chgflw_pld_o,
      input  bpu_pkg                                  l0btb_chgflw_pld_i,
      input  logic                                    l0btb_chgflw_vld_i,

      // tage ================================================
      output   logic                                  tage_pred_vld,
      output   logic [ADDR_WIDTH-1:0]                 tage_pred_pc,

      output   logic                                  tage_flush,
      // output   logic                                  tage_bp2_chgflw_vld,

      // btb =================================================
      output   logic                                  btb_pred_vld,
      output   logic   [ADDR_WIDTH-1:0]               btb_pred_pc,

      output   logic                                  btb_be_flush,
      output   logic                                  btb_be_chgflw_vld,
      output   logic   [ADDR_WIDTH-1:0]               btb_be_chgflw_pld,
      output   logic                                  btb_ras_flush,
      output   logic                                  btb_ras_enqueue_vld,
      output   logic   [ADDR_WIDTH-1:0]               btb_ras_enqueue_pld,
      output   logic                                  btb_bp2_chgflw_vld,


      // ghr =================================================
      output   logic                                  ghr_be_chgflw_vld,
      output   logic                                  ghr_be_chgflw_taken ,
      output   logic                                  ghr_be_flush,
      output   logic                                  ghr_ras_enqueue_vld,
      output   logic                                  ghr_ras_enqueue_taken,
      output   logic                                  ghr_ras_flush,

      // bpdec ===============================================
      output   logic                                  bpdec_be_flush,
      output   logic                                  bpdec_be_chgflw_vld,
      output   bpu_update_pkg                         bpdec_be_chgflw_pld,
      output   logic                                  bpdec_ras_flush,
      output   logic                                  bpdec_ras_enqueue_vld,
      input    logic                                  bpdec_bp2_chgflw_vld,
      input    bpu_pkg                                bpdec_bp2_chgflw_pld,
      input    logic                                  bpdec_entry_buffer_rdy,

      // branch target fifo ==================================
      output   logic                                  btfifo_flush,

      // rob =================================================
      output logic                                    rob_prealloc_req,
      input  logic [ROB_ENTRY_ID_WIDTH-1:0]           rob_prealloc_entry_id,

      output   logic                                  rob_flush,
      input    logic                                  rob_rdy,

      // ras ================================================
      output   logic                                  ras_flush,
      output   logic                                  ras_vld,
      output   ras_pkg                                ras_pld,
      input    bpu_pkg                                ras_chgflw_pld,
      input    logic                                  ras_chgflw_vld,

      // filter ==============================================
      output   logic                                  filter_be_chgflw_vld,
      output   logic                                  filter_ras_chgflw_vld,
      output   bpu_pkg                                filter_ras_chgflw_pld,
      input    logic                                  filter_enqueue_vld,
      input    logic   [ADDR_WIDTH-1:0]               filter_enqueue_pld,

      // backend =============================================
      input    logic  [COMMIT_CHANNEL-1:0]            be_commit_vld,
      input    be_pkg                                 be_commit_pld  [COMMIT_CHANNEL-1:0],
      input    logic  [COMMIT_CHANNEL-1:0]            be_cancel_en,
      input    logic                                  be_cancel_edge,
      input    be_pkg                                 be_cancel_pld
   );

   logic                                    pcgen_vld;
   logic                                    pcgen_pre_vld;
   logic   [ADDR_WIDTH-1:0]                 pc_nxt;
   logic   [ADDR_WIDTH-1:0]                 pc;
   logic                                    bpu_update;
   logic                                    pcgen_chgflw_vld;
   bpu_pkg                                  pcgen_chgflw_pld;

   logic                                    be_flush;
   logic                                    be_flush_flag;
   logic                                    fe_cancel_vld;
   logic                                    fe_cancel_pend;
   be_pkg                                   fe_commit_pld;
   logic                                    fe_commit_vld;
   bpu_pkg                                  fe_cancel_pld;

   logic                                    bpu_pred_buf;

   //================================================================
   // for update buffer
   //================================================================

   toy_fe_commt_buffer u_commit_buffer(
      .clk           (clk                    ),
      .rst_n         (rst_n                  ),
      .be_commit_vld (be_commit_vld          ),
      .be_commit_rdy (                       ),
      .be_commit_pld (be_commit_pld          ),
      .be_cancel_en  (be_cancel_en           ),
      .be_cancel_edge(be_cancel_edge         ),
      .be_cancel_pld (be_cancel_pld          ),
      .fe_cancel_vld (fe_cancel_vld          ),
      .fe_cancel_pend(fe_cancel_pend         ),
      .fe_commit_pld (fe_commit_pld          ),
      .fe_commit_vld (fe_commit_vld          )
   );

   assign fe_cancel_pld.pred_pc    = fe_commit_pld.bypass.pred_pc;
   assign fe_cancel_pld.tgt_pc     = fe_commit_pld.bypass.tgt_pc;
   assign fe_cancel_pld.taken      = fe_commit_pld.bypass.taken;
   assign fe_cancel_pld.offset     = fe_commit_pld.bypass.offset;
   assign fe_cancel_pld.is_cext    = fe_commit_pld.bypass.is_cext;
   assign fe_cancel_pld.carry      = fe_commit_pld.bypass.carry;
   assign fe_cancel_pld.need_align = 1'b0;

   // flush
   assign be_flush       = be_cancel_edge | be_flush_flag;

   always_ff @(posedge clk or negedge rst_n) begin
      if (~rst_n)                            be_flush_flag <= 1'b0;
      else if(fe_cancel_vld)                 be_flush_flag <= 1'b0;
      else if(be_cancel_edge)                be_flush_flag <= 1'b1;
   end

   //================================================================
   // for PCGEN: bp0 chgflw, bpdec mispred, ras mispred, be mispred
   //================================================================
   assign rob_prealloc_req     = pcgen_vld;

   assign icache_req_vld       = pcgen_pre_vld;
   assign icache_req_addr      = {pc[ADDR_WIDTH-1:ALIGN_WIDTH], {ALIGN_WIDTH{1'b0}}};
   assign icache_req_entry_id  = rob_prealloc_entry_id;

   assign l0btb_pred_vld       = pcgen_vld && ~bpu_update;
   assign l0btb_pred_pc        = pc;

   assign btb_pred_vld         = pcgen_vld && ~bpu_update;
   assign btb_pred_pc          = pc;

   assign tage_pred_vld        = pcgen_vld && ~bpu_update;
   assign tage_pred_pc         = pc;

   assign pcgen_pre_vld        = bpdec_entry_buffer_rdy && rob_rdy;
   assign pcgen_vld            = icache_req_rdy && bpdec_entry_buffer_rdy && rob_rdy;
   assign pc_nxt               = pcgen_chgflw_vld ? pcgen_chgflw_pld.tgt_pc : (pc + (PRED_BLOCK_LEN*4));

   assign bpu_update           = bpdec_bp2_chgflw_vld | be_flush | ras_chgflw_vld;

   always_ff @(posedge clk or negedge rst_n) begin
      if(~rst_n)                               bpu_pred_buf <= 1'b0;
      else if(pcgen_vld && ~bpu_update)        bpu_pred_buf <= 1'b1;
      else                                     bpu_pred_buf <= 1'b0;
   end

   always_ff @(posedge clk or negedge rst_n) begin
      if (~rst_n)                              pc <= 32'h8000_0000;
      else if(pcgen_chgflw_vld)                pc <= pc_nxt;
   end

   //================================================================
   // Changeflow Ctrl path
   //================================================================
   // For pcgen: 1. cancel from commit buffer; 2. ras chgflw; 3. bp2 chgflw; 4. l0btb chgflw
   assign pcgen_chgflw_vld               = fe_cancel_vld | ras_chgflw_vld | bpdec_bp2_chgflw_vld | l0btb_chgflw_vld_i;

   // For l0btb: 1. bp2 chgflw
   assign l0btb_chgflw_vld_o             = bpdec_bp2_chgflw_vld;

   // For tage to flush DFF:  1. cancel from commit buffer; 2. ras chgflw
   assign tage_flush                     = ras_chgflw_vld|fe_cancel_vld;

   // For btb to update hist reg and flush DFF:
   //    1. cancel from commit buffer; 2. ras chgflw; 3. bp2 chgflw
   //       when bp2 chgflw occur and pcgen stall, there is no need to update hist reg.
   assign btb_bp2_chgflw_vld             = bpdec_bp2_chgflw_vld && bpu_pred_buf;
   assign btb_be_flush                   = fe_cancel_vld;
   assign btb_be_chgflw_vld              = fe_commit_vld && ~fe_cancel_pend;
   assign btb_ras_flush                  = ras_chgflw_vld;
   assign btb_ras_enqueue_vld            = filter_enqueue_vld;

   // For bpdec: 1. cancel from commit buffer; 2. ras chgflw
   assign bpdec_be_flush                 = fe_cancel_vld;
   assign bpdec_be_chgflw_vld            = fe_commit_vld && ~fe_cancel_pend;
   assign bpdec_ras_flush                = ras_chgflw_vld;
   assign bpdec_ras_enqueue_vld          = filter_enqueue_vld;

   // For rob: 1. cancel from commit buffer; 2. ras chgflw
   assign rob_flush                      = be_flush | ras_chgflw_vld;

   // For branch target fifo: 1. cancel from commit buffer; 2. ras chgflw
   assign btfifo_flush                   = be_flush | ras_chgflw_vld;

   // For filter: 1. cancel from commit buffer; 2. ras chgflw
   assign filter_be_chgflw_vld           = be_flush;
   assign filter_ras_chgflw_vld          = ras_chgflw_vld;

   // For ghr: 1. cancel from commit buffer; 2. ras chgflw
   assign ghr_be_chgflw_vld              = fe_commit_vld;
   assign ghr_be_flush                   = fe_cancel_vld;
   assign ghr_ras_enqueue_vld            = filter_enqueue_vld;
   assign ghr_ras_flush                  = ras_chgflw_vld;

   // For ras: 1. cancel from commit buffer; 2. filter
   assign ras_flush                      = fe_cancel_vld;
   assign ras_vld                        = fe_commit_vld;
   assign ras_pld.inst_type              = {fe_commit_pld.is_ret, fe_commit_pld.is_call};

   //================================================================
   // Changeflow Data path
   //================================================================
   // for pcgen
   assign pcgen_chgflw_pld =  fe_cancel_vld            ? fe_cancel_pld            :
   ras_chgflw_vld          ? ras_chgflw_pld           :
   bpdec_bp2_chgflw_vld    ? bpdec_bp2_chgflw_pld     :
   l0btb_chgflw_pld_i;

   // for bp1
   assign l0btb_chgflw_pld_o.pred_pc   = bpdec_bp2_chgflw_pld.pred_pc;
   assign l0btb_chgflw_pld_o.taken     = bpdec_bp2_chgflw_pld.taken;
   assign l0btb_chgflw_pld_o.tgt_pc    = bpdec_bp2_chgflw_pld.tgt_pc;
   assign l0btb_chgflw_pld_o.offset    = bpdec_bp2_chgflw_pld.offset;
   assign l0btb_chgflw_pld_o.is_cext   = bpdec_bp2_chgflw_pld.is_cext;
   assign l0btb_chgflw_pld_o.carry     = bpdec_bp2_chgflw_pld.carry;

   // for bp2
   assign btb_be_chgflw_pld            = fe_commit_pld.bypass.pred_pc;
   assign btb_ras_enqueue_pld          = filter_enqueue_pld;

   // for bpdec
   assign bpdec_be_chgflw_pld.pred_pc           = fe_commit_pld.bypass.pred_pc;
   assign bpdec_be_chgflw_pld.taken             = fe_commit_pld.bypass.taken;
   assign bpdec_be_chgflw_pld.taken_err         = fe_commit_pld.taken_err;
   assign bpdec_be_chgflw_pld.tgt_pc            = fe_commit_pld.bypass.tgt_pc;
   assign bpdec_be_chgflw_pld.offset            = fe_commit_pld.bypass.offset;
   assign bpdec_be_chgflw_pld.is_cext           = fe_commit_pld.bypass.is_cext;
   assign bpdec_be_chgflw_pld.carry             = fe_commit_pld.bypass.carry;

   // for filter
   assign filter_ras_chgflw_pld    = ras_chgflw_pld;

   // for ghr
   assign ghr_be_chgflw_taken         = fe_commit_pld.bypass.taken;
   assign ghr_ras_enqueue_taken       = ras_chgflw_pld.taken;

   // for ras
   assign ras_pld.pc                  = fe_commit_pld.pc;
   assign ras_pld.pred_pc             = fe_commit_pld.bypass.pred_pc;
   assign ras_pld.offset              = fe_commit_pld.bypass.offset;
   assign ras_pld.is_cext             = fe_commit_pld.bypass.is_cext;
   assign ras_pld.carry               = fe_commit_pld.bypass.carry;
   assign ras_pld.tgt_pc              = fe_commit_pld.bypass.tgt_pc;














`ifdef TOY_SIM

   logic [63:0] tage_err;
   logic [63:0] bp2_chgflw_cnt;
   logic [63:0] ras_chgflw_cnt;


   always_ff @(posedge clk or negedge rst_n) begin
      if(~rst_n)                      bp2_chgflw_cnt    <= 0;
      else if(bpdec_bp2_chgflw_vld)   bp2_chgflw_cnt    <= bp2_chgflw_cnt + 1;
   end

   always_ff @(posedge clk or negedge rst_n) begin
      if(~rst_n)                      ras_chgflw_cnt <= 0;
      else if(ras_chgflw_vld)         ras_chgflw_cnt <= ras_chgflw_cnt + 1;
   end

   logic [31:0] total_err;

   assign total_err = fe_commit_vld&&fe_commit_pld.taken_err;

   always_ff @(posedge clk or negedge rst_n) begin
      if(~rst_n)                      tage_err <= 0;
      else if(fe_commit_vld)          tage_err <= tage_err + total_err;
   end


//    initial begin
//       forever begin
//          @(posedge clk)
//             if(1) begin
//                $display("====== fe_ctrl_chgflw detect test !!!");
//                $display("pcgen stall   [%b]",bpu_update);
//                $display("icache chgflw [%b]",~pcgen_chgflw_rdy);
//                $display("l0btb  chgflw [%b] [%h]",l0btb_chgflw_vld_i, l0btb_chgflw_pld_i.tgt_pc);
//                $display("tage chgflw   [%b]",tage_rdy);
//                $display("btb chgflw    [%b]",btb_rdy);
//                $display("bp2dec chgflw [%b] [%h]",bpdec_bp2_chgflw_vld, bpdec_bp2_chgflw_pld.tgt_pc);
//                $display("rob chgflw    [%b]",rob_rdy);
//                $display("ras chgflw    [%b] [%h]",ras_chgflw_vld, ras_chgflw_pld.tgt_pc);
//                $display("be chgflw     [%b] [%h] [%h]",be_cancel_edge, be_cancel_pld.pc, be_cancel_pld.bypass.tgt_pc);
//             end
//       end
//    end
`endif

endmodule