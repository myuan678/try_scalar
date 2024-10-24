
module toy_env_slv #(
    parameter integer unsigned ADDR_WIDTH = 32,
    parameter integer unsigned DATA_WIDTH = 32
) (
    output logic                        clk         ,
    output logic                        rst_n       ,

    input  logic                        en          ,
    input  logic [ADDR_WIDTH-1:0]       addr        ,
    output logic [DATA_WIDTH-1:0]       rd_data     ,
    input  logic [DATA_WIDTH-1:0]       wr_data     ,
    input  logic [DATA_WIDTH/8-1:0]     wr_byte_en  ,
    input  logic                        wr_en       
);
    int unsigned timeout_cycle;
    int cycle;

    assign rd_data = 0;

//============================================================
// Clock and Reset generation
//============================================================

    initial begin
        cycle = 0;
        forever begin
            @(posedge clk)
            cycle = cycle + 1;
        end
    end


    // #20 is a cycle.

    initial begin
        timeout_cycle = 20000;
        if($value$plusargs("TIMEOUT=%d", timeout_cycle)) begin
            $display("[SYSTEM] Timeout threshold is set to %0d cycles.", timeout_cycle);
        end
        else begin
            $display("[SYSTEM] Used default timeout setting %0d cycles.", timeout_cycle);
        end

        rst_n = 1'b0;
        #100;
        rst_n = 1'b1;
        if(timeout_cycle == 0) begin

        end
        else begin
        for(int i=0;i<timeout_cycle;i=i+1) begin
           #20;
        end
        $fatal("[SYSTEM] Timeout occurs after executing %0d cycles !", timeout_cycle);
        end
    end

    parameter STDIN = 32'h8000_0000;

    string command = "" ;    
    string char0        ;
    string char01       ;
    string char012      ;
    string print_buffer ;
    string print_char   ;

    logic [31:0]    pc        [7:0]     ;
    logic [31:0]    target_pc           ;
    logic [31:0]    registers [0:31]    ;
    logic [31:0]    fp_registers [0:31]    ;
    // logic [31:0]    reg_lock_cnt        ;
    logic [63:0]    mcycle              ;
    logic [63:0]    minstret            ;
    logic [63:0]    cancel_inst_cnt     ;
    logic [7:0]    commit_depth;
    logic [7:0]    commit_depth_min;
    logic [7:0]    commit_depth_min_rev;
    logic [5:0]lsu_dep;
    logic [5:0]lsu_dep_max;
    logic [7:0]stu_dep;
    logic [7:0]stu_dep_min;
    logic [7:0]stu_dep_min_rev;
    logic [7:0]ldu_dep;
    logic [7:0]ldu_dep_min;
    logic [7:0]ldu_dep_min_rev;


    // logic [9:0] num_error [9:0];
    int tmp;
    logic   [7-1  :0]     fp_rf_dep       [4-1:0];
    logic   [7-1  :0]     int_rf_dep       [4-1:0];
    logic   [7-1  :0]     fp_rf_dep_max       ;
    logic   [7-1  :0]     int_rf_dep_max       ;
    // generate for(genvar i=0;i<32;i=i+1) begin
    //     assign registers[i] = u_toy_scalar.u_core.u_dispatch.u_rf.registers[i];
    // end endgenerate
    assign registers    = u_toy_scalar.u_core.u_dispatch.registers_shadow;
    assign fp_registers = u_toy_scalar.u_core.u_dispatch.fp_registers_shadow;
    // assign reg_lock_cnt = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.reg_lock_cnt;
    assign minstret     = u_toy_scalar.u_core.u_csr.csr_INSTRET;
    assign mcycle       = u_toy_scalar.u_core.u_csr.csr_CYCLE;
    assign pc           = u_toy_scalar.u_core.u_fetch.v_ack_pc;
    // assign num_error    = u_toy_scalar.u_core.u_toy_commit.num_error;
    assign cancel_inst_cnt = u_toy_scalar.u_core.u_toy_commit.cancel_inst_cnt;
    assign commit_depth = u_toy_scalar.u_core.u_fetch.commit_credit_cnt;
    assign fp_rf_dep = u_toy_scalar.u_core.u_dispatch.u_fp_regfile.u_toy_physicial_regfile.v_pre_allocate_id;
    assign int_rf_dep = u_toy_scalar.u_core.u_dispatch.u_int_regfile.u_toy_physicial_regfile.v_pre_allocate_id;
    assign lsu_dep = u_toy_scalar.u_core.u_toy_lsu.u_toy_lsu_buffer.queue_cnt;
    assign stu_dep = u_toy_scalar.u_core.u_toy_lsu.u_toy_lsu_buffer.stu_credit_cnt;
    assign ldu_dep = u_toy_scalar.u_core.u_toy_lsu.u_toy_lsu_buffer.ldu_credit_cnt;


    assign stu_dep_min_rev = 'd32 - stu_dep_min;
    assign ldu_dep_min_rev = 'd32 - ldu_dep_min;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            stu_dep_min <= 7'h7f;
        end
        else if(stu_dep_min > stu_dep)begin
            stu_dep_min <= stu_dep;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            ldu_dep_min <= 7'h7f;
        end
        else if(ldu_dep_min > ldu_dep)begin
            ldu_dep_min <= ldu_dep;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            lsu_dep_max <= 0;
        end
        else if(lsu_dep > lsu_dep_max)begin
            lsu_dep_max <= lsu_dep;
        end
    end  


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            fp_rf_dep_max <= 0;
        end
        else if(fp_rf_dep[3] > fp_rf_dep_max)begin
            fp_rf_dep_max <= fp_rf_dep[3];
        end
    end  
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            int_rf_dep_max <= 0;
        end
        else if(int_rf_dep[3] > int_rf_dep_max)begin
            int_rf_dep_max <= int_rf_dep[3];
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            commit_depth_min <= 8'h80;
        end
        else if(commit_depth_min > commit_depth)begin
            commit_depth_min <= commit_depth;
        end
    end

    assign commit_depth_min_rev = 'd64 - commit_depth_min;

    logic [4-1:0] v_monitor_fetch_vld;
    logic [4-1:0] v_monitor_issue_vld;
    logic [4-1:0] v_monitor_issue_rdy;
    logic [4-1:0] v_monitor_eu_hazard;
    logic [4-1:0] v_monitor_reg_lock;
    logic [4-1:0] v_monitor_phy_lock;

    assign v_monitor_fetch_vld = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_dec_inst_vld;
    assign v_monitor_issue_vld = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_eu_vld;
    assign v_monitor_issue_rdy = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_eu_rdy;
    assign v_monitor_eu_hazard = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_monitor_eu_hazard;
    assign v_monitor_reg_lock = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_monitor_reg_lock;
    assign v_monitor_phy_lock = u_toy_scalar.u_core.u_dispatch.u_toy_dispatch_issue.v_monitor_phy_lock;


    // logic [63:0] fetch_lock_cnt;
    // logic [63:0] previous_lock_cnt;
    // logic [63:0] reg_lock_cnt;
    // logic [63:0] eu_lock_cnt;    
    
    logic [63:0] fetch_lock_cnt_entry   [3:0];
    logic [63:0] previous_lock_cnt_entry[3:0];
    logic [63:0] reg_lock_cnt_entry     [3:0];
    logic [63:0] phy_lock_cnt_entry     [3:0];
    logic [63:0] eu_lock_cnt_entry      [3:0];
    logic [63:0] same_time_lock_entry      [3:0];
    // logic [3:0] fetch_lock_add [3:0];
    // logic [3:0] previous_lock_add [3:0];
    // logic [3:0] reg_lock_add [3:0];
    // logic [3:0] eu_lock_add [3:0];

    logic [3:0] fetch_lock_flag ;
    logic [3:0] previous_lock_flag ;
    logic [3:0] reg_lock_flag ;
    logic [3:0] eu_lock_flag ;
    logic [3:0] phy_lock_flag ;
    logic [3:0] same_time_lock_flag ;
    // always_ff @(posedge clk or negedge rst_n) begin
    //     if(~rst_n)begin
    //         fetch_lock_cnt <= 0;
    //         previous_lock_cnt <= 0;
    //         reg_lock_cnt <= 0;
    //         eu_lock_cnt <= 0;
    //     end
    //     else begin
    //         fetch_lock_cnt <= fetch_lock_cnt + fetch_lock_add[3];
    //         previous_lock_cnt <= previous_lock_cnt + previous_lock_add[3];
    //         reg_lock_cnt <= reg_lock_cnt + reg_lock_add[3];
    //         eu_lock_cnt <= eu_lock_cnt + eu_lock_add[3];
    //     end
    // end




    // always_ff @(posedge clk or negedge rst_n) begin
    //     if(~rst_n)begin
    //         fetch_lock_cnt_entry[0] <= 0;
    //         previous_lock_cnt_entry[0] <= 0;
    //         reg_lock_cnt_entry[0] <= 0;
    //         eu_lock_cnt_entry[0] <= 0;
    //         same_time_lock_entry[0] <= 0;
    //     end
    //     else begin
    //         fetch_lock_cnt_entry[0] <= fetch_lock_cnt_entry[0] + fetch_lock_flag[0];
    //         previous_lock_cnt_entry[0] <= previous_lock_cnt_entry[0] + previous_lock_flag[0];
    //         reg_lock_cnt_entry[0] <= reg_lock_cnt_entry[0] + reg_lock_flag[0];
    //         eu_lock_cnt_entry[0] <= eu_lock_cnt_entry[0] + eu_lock_flag[0];
    //         same_time_lock_entry[0] <= same_time_lock_entry[0] + same_time_lock_flag[0];
    //     end
    // end


    logic [2:0] type_enc [3:0];
    logic [31:0] entry_cnt [35:0];
    generate
        for (genvar p=0;p<36;p=p+1)begin
            if(p%9==8)begin
                always_ff @(posedge clk or negedge rst_n) begin 
                    if(~rst_n)begin
                        entry_cnt[p] <= 0;
                    end
                    else begin
                        entry_cnt[p] <= entry_cnt[p] + fetch_lock_flag[p/9];
                    end
                end
            end
            else begin
                always_ff @(posedge clk or negedge rst_n) begin 
                    if(~rst_n)begin
                        entry_cnt[p] <= 0;
                    end
                    else if(type_enc[p/9] == (p%9))begin
                        if(fetch_lock_flag[p/9]==0)begin
                            entry_cnt[p] <= entry_cnt[p] + 1;
                        end
                    end
                end
            end
        end


        for(genvar p=0;p<4;p=p+1)begin
            assign type_enc[p] = {previous_lock_flag[p],reg_lock_flag[p],eu_lock_flag[p]};
            always_ff @(posedge clk or negedge rst_n) begin
                if(~rst_n)begin
                    fetch_lock_cnt_entry[p] <= 0;
                    previous_lock_cnt_entry[p] <= 0;
                    reg_lock_cnt_entry[p] <= 0;
                    phy_lock_cnt_entry[p] <= 0;
                    eu_lock_cnt_entry[p] <= 0;
                end
                else begin
                    fetch_lock_cnt_entry[p] <= fetch_lock_cnt_entry[p] + fetch_lock_flag[p];
                    previous_lock_cnt_entry[p] <= previous_lock_cnt_entry[p] + previous_lock_flag[p];
                    reg_lock_cnt_entry[p] <= reg_lock_cnt_entry[p] + reg_lock_flag[p];
                    phy_lock_cnt_entry[p] <= phy_lock_cnt_entry[p] + phy_lock_flag[p];
                    eu_lock_cnt_entry[p] <= eu_lock_cnt_entry[p] + eu_lock_flag[p];
                end
            end
            if(p==0)begin
                assign fetch_lock_flag[0] = ~v_monitor_fetch_vld[0] ? 1 : 0;
                assign previous_lock_flag[0] = 0;
                assign reg_lock_flag[0] =  (fetch_lock_flag[0]==1)  ? 0 :
                                            v_monitor_reg_lock[0] ? 1:0;
                assign eu_lock_flag[0] =   (fetch_lock_flag[0]==1)  ? 0 :
                                            v_monitor_eu_hazard[0] ? 1:0;
                assign phy_lock_flag[0] =   (fetch_lock_flag[0]==1)  ? 0 :
                                            v_monitor_phy_lock[0] ? 1:0;            
                end
            else begin
                always_comb begin
                    fetch_lock_flag[p]       = 1'b0;
                    previous_lock_flag[p]    = 1'b0;
                    reg_lock_flag[p]         = 1'b0;
                    eu_lock_flag[p]          = 1'b0;
                    same_time_lock_flag[p]   = 1'b0;
                    phy_lock_flag[p] =  1'b0;
                    if(~v_monitor_fetch_vld[p])begin
                        fetch_lock_flag[p] =   1'b1;
                    end
                    else begin
                        if(~(v_monitor_issue_vld[p-1] & v_monitor_issue_rdy[p-1]))begin
                            previous_lock_flag[p] = 1'b1;
                        end
                        if(v_monitor_reg_lock[p])begin
                            reg_lock_flag[p] =  1'b1;
                        end
                        if(v_monitor_eu_hazard[p])begin
                            eu_lock_flag[p] =  1'b1;
                        end
                        if(v_monitor_phy_lock[p])begin
                            phy_lock_flag[p] =  1'b1;
                        end
                    end
                end

            end
        end
    endgenerate




    initial begin
        clk = 1'b0;
        if($test$plusargs("DEBUG")) begin
            $display("Toy Terminal:");
            forever begin
                $write("(toy):");
                tmp = $fscanf(STDIN, "%s", command);
                $display("command: \"%s\"",command);
                if(command == "") begin

                end
                else begin
                    char0       = $sformatf("%s", command.substr(0, 0));
                    char01      = $sformatf("%s", command.substr(0, 1));
                    char012     = $sformatf("%s", command.substr(0, 2));
                    if(char012 == "upc") begin
                        $display("Get upc command: \"%s\"", command);
                        if ($sscanf(command, "upc=%h", target_pc) == 1) begin
                            $display("Target pc = %h", target_pc);
                            forever begin
                                if((pc[0] == target_pc)|(pc[1] == target_pc)|(pc[2] == target_pc)|(pc[3] == target_pc)) begin
                                    break; 
                                end
                                else begin
                                    #10;
                                    clk = ~clk;
                                    #10;
                                    clk = ~clk;
                                end
                            end
                        end else begin
                            $display("Failed to extract values from the string upc;");
                        end
                    end
                    else if (char012 == "reg") begin
                        $display("zero: 0x%h  ra: 0x%h  sp: 0x%h  gp: 0x%h", registers[0]    ,registers[1]   ,registers[2]   ,registers[3]   );
                        $display("  tp: 0x%h  t0: 0x%h  t1: 0x%h  t2: 0x%h", registers[4]    ,registers[5]   ,registers[6]   ,registers[7]   );
                        $display("  s0: 0x%h  s1: 0x%h  a0: 0x%h  a1: 0x%h", registers[8]    ,registers[9]   ,registers[10]  ,registers[11]  );
                        $display("  a2: 0x%h  a3: 0x%h  a4: 0x%h  a5: 0x%h", registers[12]   ,registers[13]  ,registers[14]  ,registers[15]  );
                        $display("  a6: 0x%h  a7: 0x%h  s2: 0x%h  s3: 0x%h", registers[16]   ,registers[17]  ,registers[18]  ,registers[19]  );
                        $display("  s4: 0x%h  s5: 0x%h  s6: 0x%h  s7: 0x%h", registers[20]   ,registers[21]  ,registers[22]  ,registers[23]  );
                        $display("  s8: 0x%h  s9: 0x%h s10: 0x%h s11: 0x%h", registers[24]   ,registers[25]  ,registers[26]  ,registers[27]  );
                        $display("  t3: 0x%h  t4: 0x%h  t5: 0x%h  t6: 0x%h", registers[28]   ,registers[29]  ,registers[30]  ,registers[31]  );
                    end

                    else if (char012 == "fr") begin
                        $display(" fp0: 0x%h   fp1: 0x%h   fp2: 0x%h   fp3: 0x%h", fp_registers[0]    ,fp_registers[1]   ,fp_registers[2]   ,fp_registers[3]   );
                        $display(" fp4: 0x%h   fp5: 0x%h   fp6: 0x%h   fp7: 0x%h", fp_registers[4]    ,fp_registers[5]   ,fp_registers[6]   ,fp_registers[7]   );
                        $display(" fp8: 0x%h   fp9: 0x%h  fp10: 0x%h  fp11: 0x%h", fp_registers[8]    ,fp_registers[9]   ,fp_registers[10]  ,fp_registers[11]  );
                        $display("fp12: 0x%h  fp13: 0x%h  fp14: 0x%h  fp15: 0x%h", fp_registers[12]   ,fp_registers[13]  ,fp_registers[14]  ,fp_registers[15]  );
                        $display("fp16: 0x%h  fp17: 0x%h  fp18: 0x%h  fp19: 0x%h", fp_registers[16]   ,fp_registers[17]  ,fp_registers[18]  ,fp_registers[19]  );
                        $display("fp20: 0x%h  fp21: 0x%h  fp22: 0x%h  fp23: 0x%h", fp_registers[20]   ,fp_registers[21]  ,fp_registers[22]  ,fp_registers[23]  );
                        $display("fp24: 0x%h  fp25: 0x%h  fp26: 0x%h  fp27: 0x%h", fp_registers[24]   ,fp_registers[25]  ,fp_registers[26]  ,fp_registers[27]  );
                        $display("fp28: 0x%h  fp29: 0x%h  fp30: 0x%h  fp31: 0x%h", fp_registers[28]   ,fp_registers[29]  ,fp_registers[30]  ,fp_registers[31]  );
                    end

                    else if(char0 == "r") begin
                        #10;
                        clk = ~clk;
                        #10;
                        clk = ~clk;
                    end
                    else if(char0 == "q") begin
                        break;
                    end
                    else if(char0 == "\n") begin

                    end
                    else if(char01 == "pc") begin
                        $display("pc = %h %h %h %h", pc[3],pc[2],pc[1],pc[0]);
                    end
                end

            end
        end
        else begin
            forever begin
                #10;
                clk = ~clk;
                #10;
                clk = ~clk;
            end
        end
    end




    logic [31:0] fetch_entry_cnt [3:0];
    logic [31:0] fetch_0_cnt;
    assign fetch_entry_cnt = u_toy_scalar.u_core.u_dispatch.fetch_entry_cnt;
    assign fetch_0_cnt = u_toy_scalar.u_core.u_dispatch.fetch_0_cnt;
    logic [31:0] fix_cycle;
    logic [31:0] mem_cycle;
    assign fix_cycle = u_toy_scalar.u_core.u_toy_lsu.fix_cycle;
    assign mem_cycle = u_toy_scalar.u_core.u_toy_lsu.mem_cycle;
    logic fix_priority;
    logic [7:0]fetch_vld;
    logic [7:0]fetch_rdy;
    logic ld_lsid;
    assign ld_lsid = u_toy_scalar.u_core.u_toy_lsu.v_load_pld[0].lsid;
    assign fix_priority = u_toy_scalar.u_core.u_toy_lsu.fix_priority;
    assign fetch_vld = u_toy_scalar.u_core.u_fetch.v_ack_vld;
    assign fetch_rdy = u_toy_scalar.u_core.u_fetch.v_ack_rdy;
    logic fetch_en;
    assign fetch_en = fetch_vld & fetch_rdy;
    logic [31:0] hazard_by_load;
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            hazard_by_load<=0;
        end
        else if(~|fetch_en && fix_priority && ld_lsid)begin
            hazard_by_load<=hazard_by_load+1;
            
        end
        
    end

                            
    int int_array[31:0];

    import "DPI-C" function void draw_pic(input int numbers [31:0]);


    real mpki;
    logic [63:0] ras_error_cnt;
    logic [63:0] btb_error_cnt;
    logic [63:0] tage_error_cnt;
    logic [63:0] ras_miss_error_cnt;
    logic [63:0] ind_btb_error_cnt;

    assign ras_error_cnt  = u_toy_scalar.u_core.u_toy_commit.ras_error_cnt;
    assign btb_error_cnt  = u_toy_scalar.u_core.u_toy_commit.btb_error_cnt;
    assign tage_error_cnt = u_toy_scalar.u_core.u_toy_commit.tage_error_cnt;
    assign ras_miss_error_cnt = u_toy_scalar.u_core.u_toy_commit.ras_miss_error_cnt;
    assign ind_btb_error_cnt = u_toy_scalar.u_core.u_toy_commit.ind_btb_error_cnt;

    logic [63:0] bp2_chgflw_cnt;
    logic [63:0] ras_chgflw_cnt;

    assign bp2_chgflw_cnt  = u_toy_scalar.u_core.u_bpu.u_fe_ctrl.bp2_chgflw_cnt;
    assign ras_chgflw_cnt  = u_toy_scalar.u_core.u_bpu.u_fe_ctrl.ras_chgflw_cnt;

    logic [63:0] update_cnt;
    logic [63:0] real_commit;

    assign update_cnt = u_toy_scalar.u_core.u_bpu.u_bpdec.u_entry_buffer.update_cnt;
    assign real_commit = u_toy_scalar.u_core.u_bpu.u_bpdec.u_entry_buffer.real_commit;

    logic [63:0] real_tage_err;
    assign real_tage_err = u_toy_scalar.u_core.u_bpu.u_fe_ctrl.tage_err;


    // always_ff @(posedge clk) begin
    initial begin
        print_char      = "";
        print_buffer    = "";
        forever begin

            @(posedge clk)
            if(en) begin
                if(wr_en) begin
                    //if($test$plusargs("DEBUG"))
                    if(((addr*8)>=0)&&((addr*8)<=1023)) begin
                        $display("[SYSTEM][cycle=%d][pc=%h] Receive a cmd from core, cmd[%h] = %h", cycle, pc[0], addr*8, wr_data);

                        if($test$plusargs("DEBUG") | $test$plusargs("DUMP")) begin
                            for(int i=0;i<32;i++) begin
                                $display("x%0d = %h", i, registers[i]);
                            end
                        end
                        $display("[SYSTEM][cycle=%d][pc=%h] Receive exit command %h, exit.", cycle, pc[0], wr_data);
                        $display("[SYSTEM][PERF]Total %10d cycles.",                      mcycle);
                        $display("[SYSTEM][PERF]Total %10d instructions.",                minstret);
                        $display("[SYSTEM][PERF]Total %10d times cancel.MPKI %5f",        cancel_inst_cnt, (real'(cancel_inst_cnt) * 1000.0) / real'(minstret));
                        $display("[SYSTEM][BP]Tage error: %5d, BTB error: %5d, RAS error: %5d, RAS miss: %5d, Ind error: %5d.",tage_error_cnt, btb_error_cnt, ras_error_cnt, ras_miss_error_cnt, ind_btb_error_cnt);
                        $display("[SYSTEM][BP]BP2 chgflw: %5d, RAS chgflw: %5d.",bp2_chgflw_cnt, ras_chgflw_cnt);
                        $display("[SYSTEM][BP]Tage update num: %5d, Real commit: %5d, Real tage err: %5d.",update_cnt, real_commit, real_tage_err);
                        // $display("[SYSTEM][BP]MPKI last 10k      %5f,%5f,%5f,%5f,%5f,%5f,%5f,%5f,%5f,%5f.",1000/num_error[0],1000/num_error[1],1000/num_error[2],1000/num_error[3],1000/num_error[4],1000/num_error[5],1000/num_error[6],1000/num_error[7],1000/num_error[8],1000/num_error[9]);
                        
                        // $display("[SYSTEM][PERF]Stall %10d cycles due to register dep.",  reg_lock_cnt);
                        $display("[SYSTEM][ENTRY_USE]Fetch entry 0 use %d.",  fetch_entry_cnt[0]);
                        $display("[SYSTEM][ENTRY_USE]Fetch entry 1 use %d.",  fetch_entry_cnt[1]);
                        $display("[SYSTEM][ENTRY_USE]Fetch entry 2 use %d.",  fetch_entry_cnt[2]);
                        $display("[SYSTEM][ENTRY_USE]Fetch entry 3 use %d.",  fetch_entry_cnt[3]);
                        $display("[SYSTEM][LSU]Memory req cycle num %d.",  mem_cycle);
                        $display("[SYSTEM][COMMIT]MAX use %d.",  commit_depth_min_rev);
                        $display("[SYSTEM][INT_RF]MAX use %d.",  int_rf_dep_max);
                        $display("[SYSTEM][FP_RF]MAX use %d.",  fp_rf_dep_max);
                        $display("[SYSTEM][LSU]MAX use %d.",  lsu_dep_max);
                        $display("[SYSTEM][STQ]MAX use %d.",  stu_dep_min_rev);
                        $display("[SYSTEM][LDQ]MAX use %d.",  ldu_dep_min_rev);
                        
                        // $display("[SYSTEM][ENTRY_USE]None of Fetch channels are used %d.",  fetch_0_cnt);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 0 empty %d.",  fetch_lock_cnt_entry[0]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 1 empty %d.",  fetch_lock_cnt_entry[1]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 2 empty %d.",  fetch_lock_cnt_entry[2]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 3 empty %d.",  fetch_lock_cnt_entry[3]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 0 in-order pending %d.",  previous_lock_cnt_entry[0]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 1 in-order pending %d.",  previous_lock_cnt_entry[1]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 2 in-order pending %d.",  previous_lock_cnt_entry[2]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 3 in-order pending %d.",  previous_lock_cnt_entry[3]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 0 empty %10d.in-order pending %10d.reg_hazard %10d.eu_hazard %10d.same_cycle %10d.", entry_cnt[8],entry_cnt[0], entry_cnt[0],entry_cnt[0],entry_cnt[0]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 1 empty %10d.in-order pending %10d.reg_hazard %10d.eu_hazard %10d.same_cycle %10d.", entry_cnt[17],entry_cnt[1], entry_cnt[1],entry_cnt[1],entry_cnt[1]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 2 empty %10d.in-order pending %10d.reg_hazard %10d.eu_hazard %10d.same_cycle %10d.", entry_cnt[26],entry_cnt[2], entry_cnt[2],entry_cnt[2],entry_cnt[2]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 3 empty %10d.in-order pending %10d.reg_hazard %10d.eu_hazard %10d.same_cycle %10d.", entry_cnt[35],entry_cnt[3], entry_cnt[3],entry_cnt[3],entry_cnt[3]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 0 eu_hazard %d.",  eu_lock_cnt_entry[0]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 1 eu_hazard %d.",  eu_lock_cnt_entry[1]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 2 eu_hazard %d.",  eu_lock_cnt_entry[2]);
                        // $display("[SYSTEM][ENTRY_USE]Fetch entry 3 eu_hazard %d.",  eu_lock_cnt_entry[3]);
                        // for(int p=0;p<36;p=p+1)begin
                        //     $display("%d-%d-",p,entry_cnt[p]);
                        // end
                        
                        $display("[SYSTEM] phy_lock    %d%d%d%d",phy_lock_cnt_entry[0],phy_lock_cnt_entry[1],phy_lock_cnt_entry[2],phy_lock_cnt_entry[3]);
                        $display("[SYSTEM] eu_hazard   %d",(eu_lock_cnt_entry[0]+eu_lock_cnt_entry[1]+eu_lock_cnt_entry[2]+eu_lock_cnt_entry[3]));
                        $display("[SYSTEM] reg_hazard  %d",(reg_lock_cnt_entry[0]+reg_lock_cnt_entry[1]+reg_lock_cnt_entry[2]+reg_lock_cnt_entry[3]));
                        $display("[SYSTEM] in-order    %d",(previous_lock_cnt_entry[0]+previous_lock_cnt_entry[1]+previous_lock_cnt_entry[2]+previous_lock_cnt_entry[3]));
                        // $display("\n");
                        $display("[SYSTEM] 1->eu_hazard");
                        $display("[SYSTEM] 2->           reg_hazard");
                        $display("[SYSTEM] 3->eu_hazard  reg_hazard");
                        $display("[SYSTEM] 4->                       in-order");
                        $display("[SYSTEM] 5->eu_hazard              in-order");
                        $display("[SYSTEM] 6->           reg_hazard  in-order");
                        $display("[SYSTEM] 7->eu_hazard  reg_hazard  in-order");

                        for(int p=0;p<32;p=p+1)begin
                            if(p%8==0)begin
                                int_array[p] =  int'(entry_cnt[(p/8)*9+8]);
                            end
                            else begin
                                int_array[p] =  int'(entry_cnt[p+p/8]);
                            end
                        end
                        draw_pic(int_array);
                        // $display("[SYSTEM][ENTRY_USE]None of Fetch channels are used %d.",  fetch_0_cnt);

                        // $display("[SYSTEM][LSU]Load priority num %d.",  fix_cycle);
                        // $display("[SYSTEM][LSU]Load priority release hazard num %d.",  hazard_by_load);
                        if(wr_data[0]==1'b1) begin
                            if(wr_data[31:1]==0) begin
                                // $display("wait commit queue empty.");
                                
                                $display("receive exit signal 0, success exit.");
                                $finish;
                            end
                            else begin
                                $fatal("receive exit signal %d, fatal exit." , wr_data[31:1]);
                            end
                        end

                    end
                    else if(addr*8==1024) begin

                        $sformat(print_char, "%c", wr_data[7:0]);
                        if(print_char == "\n") begin
                            $display("[PRINT][cycle=%d] %s", cycle, print_buffer);
                            print_buffer = "";
                        end 
                        else begin
                            $sformat(print_buffer, "%s%s", print_buffer,print_char);
                        end

                    end
                    else begin
                        
                    end
                end
            end
        end
    end

endmodule