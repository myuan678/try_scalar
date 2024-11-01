//`timescale 1ns/1ps
module icache_top_tb();
    import toy_pack::*;
	
    logic                                        clk                         ;
    logic                                        rst_n                       ;
    logic                                        prefetch_enable             ;

    //upstream txdat  out
    logic [ICACHE_UPSTREAM_DATA_WIDTH-1:0]       upstream_txdat_data         ; 
    logic                                        upstream_txdat_vld          ;
    logic                                        upstream_txdat_rdy          ; 
    logic [ICACHE_REQ_TXNID_WIDTH-1:0]           upstream_txdat_txnid        ;

    //upstream rxreq
    logic                                        upstream_rxreq_vld          ;
    logic                                        upstream_rxreq_rdy          ;
    pc_req_t                                     upstream_rxreq_pld          ;

    //downstream rxsnp
    logic                                        downstream_rxsnp_vld        ;
    logic                                        downstream_rxsnp_rdy        ;
    pc_req_t                                     downstream_rxsnp_pld        ;

    //downtream txreq
    logic                                        downstream_txreq_vld        ;
    logic                                        downstream_txreq_rdy        ;
    pc_req_t                                     downstream_txreq_pld        ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           downstream_txreq_entry_id   ;

    //downstream txrsp
    logic                                        downstream_txrsp_vld        ;
    logic                                        downstream_txrsp_rdy        ;
    logic [ICACHE_REQ_OPCODE_WIDTH-1:0]          downstream_txrsp_opcode     ;
    
    //downstream rxdat  in
    logic                                        downstream_rxdat_vld        ;
    logic                                        downstream_rxdat_rdy        ;
    downstream_rxdat_t                           downstream_rxdat_pld        ;   

    //tb queue
    pc_req_t                                     up_req[$]               ;
    pc_req_t                                     up_req_q[$]             ;
    pc_req_t                                     txreq                   ;
    pc_req_t                                     txreq_q[$]              ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           txreq_entry_id          ;
    logic [MSHR_ENTRY_INDEX_WIDTH-1:0]           txreq_entry_id_q[$]     ;
    int                                          rxdat_delay             ;
    int up_req_cnt=0, tx_dat_cnt=0,tx_req_cnt=0,rx_dat_cnt=0,input_file_size;
    int                                          file                    ;
    int                                          read_bytes              ;
    int                                          global_up_req_cnt = 0   ;
    int                                          local_up_req_cnt  = 0   ;
    int                                          local_tx_req_cnt  = 0   ;

    typedef struct packed {
        logic [ICACHE_TAG_WIDTH-1:0]    tag     ;
        logic [ICACHE_INDEX_WIDTH-1:0]  index   ;
        logic [ICACHE_OFFSET_WIDTH-1:0] offset  ;
    } addr_t;
    addr_t  data_buffer    ;
    addr_t  upstream_rxreq ;
    //logic [31:0] tmp_buffer;
    //assign data_buffer.tag     = tmp_buffer[31:ICACHE_INDEX_WIDTH];
    //assign data_buffer.index   = tmp_buffer[ICACHE_INDEX_WIDTH+ICACHE_OFFSET_WIDTH-1:ICACHE_OFFSET_WIDTH];
    //assign data_buffer.offset  = tmp_buffer[ICACHE_OFFSET_WIDTH-1:0];
    
    assign prefetch_enable      = 1'b0;
    assign downstream_txreq_rdy = 1'b1;
    assign upstream_txdat_rdy   = 1'b1;

//========================================================
// trace log 
//========================================================
    initial begin
        file = $fopen("/home/xuemengyuan/try/cache_v1/icache/trace_replay/align_pc_trace_copy2.bin", "rb");
        if (file == 0) begin
            $display("Error: Cannot open file.");
            $finish;
        end

        while (!$feof(file)) begin
            read_bytes = $fread(data_buffer, file);
            if (read_bytes != 4) begin
                $display("Warning: Incomplete read, read %0d bytes.", read_bytes);
                break;
            end
            $display("Read 32-bit value: %h", data_buffer);
            up_req_q.push_back(data_buffer);
        end

        $fclose(file);
    end

    initial begin
    	clk = 0;
        upstream_rxreq_vld                = 0;
        downstream_rxsnp_vld              = 0;
    	forever #10 clk = ~clk               ;
    end
//========================================================
// request
//========================================================
    task send_upstream_req(input int tag, int index, int id);
        @(posedge clk);
        @(posedge clk);
        upstream_rxreq_vld              <= 1;
        upstream_rxreq_pld.addr.tag     <= tag;
        upstream_rxreq_pld.addr.index   <= index;
        upstream_rxreq_pld.addr.offset  <= {ICACHE_OFFSET_WIDTH{1'b1}};
        upstream_rxreq_pld.opcode       <= UPSTREAM_OPCODE;
        upstream_rxreq_pld.txnid        <= id;
        $display("send_upstream_req: tag=%d, index=%d, id=%d", tag, index, id);
        do begin
            @(posedge clk);
        end while(upstream_rxreq_rdy!==1'b1);
        up_req.push_back(upstream_rxreq_pld);
        up_req_cnt++;
        upstream_rxreq_vld              <= 0;
        upstream_rxreq_pld.addr.tag     <= 0;
        upstream_rxreq_pld.addr.index   <= 0;
        upstream_rxreq_pld.addr.offset  <= 0;
        upstream_rxreq_pld.opcode       <= 0;
        upstream_rxreq_pld.txnid        <= 0;
        //end
    endtask

    task send_downstream_req(input int tag, int index, int id);
        @(posedge clk);
        downstream_rxsnp_vld              <= 1;
        downstream_rxsnp_pld.addr.tag     <= tag;
        downstream_rxsnp_pld.addr.index   <= index;
        downstream_rxsnp_pld.addr.offset  <= {ICACHE_OFFSET_WIDTH{1'b1}};
        downstream_rxsnp_pld.opcode       <= DOWNSTREAM_OPCODE;
        downstream_rxsnp_pld.txnid        <= id;
        $display("send_downstream_req: tag=%d, index=%d, id=%d", tag, index, id);
        do begin
            @(posedge clk);
        end while(downstream_rxsnp_rdy!==1'b1);
        downstream_rxsnp_vld              <= 0;
        downstream_rxsnp_pld.addr.tag     <= 0;
        downstream_rxsnp_pld.addr.index   <= 0;
        downstream_rxsnp_pld.addr.offset  <= 0;
        downstream_rxsnp_pld.opcode       <= 0;
        downstream_rxsnp_pld.txnid        <= 0;
    endtask 

//========================================================
// test case
//========================================================
    initial begin
        int testcase = 3;
        int delay       ;
        int tag         ;
        int index       ;
        int txnid       ;
     	rst_n = 1       ;   
    	#100 rst_n = 0  ;
        #100 rst_n = 1  ;
        repeat(3)@(posedge clk);
        case(testcase)
            1:begin//read(miss)---read(hit)
                fork
                    begin
                        for(int i=1; i<20; i++)begin
                            delay = $urandom_range(3,5);
                            send_upstream_req(i, i, i);
                            $display("send a UP req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                            repeat(delay)@(posedge clk);
                        end
                    end
                    begin 
                        for(int i=1; i<20; i++)begin
                            delay = $urandom_range(2,3);
                            send_downstream_req(i, 1, i);
                            $display("send a DOWN req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                            repeat(delay)@(posedge clk);
                        end
                    end
                join 
                #1000;
                for(int i=1; i<20; i++)begin
                    delay = $urandom_range(1,8);
                    send_upstream_req(i, i, i);
                    $display("send a up req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                    repeat(delay)@(posedge clk);
                end   
            end
            2:begin //trace replay
                input_file_size = up_req_q.size();
                for(int i=0; i<input_file_size; i++)begin
                    data_buffer = up_req_q.pop_front();
                    $display("ADDR = %h",data_buffer );
                    tag            = data_buffer.tag  ;
                    index          = data_buffer.index;
                    txnid          = i%32;
                    @(posedge clk);
                    send_upstream_req(tag, index, txnid);
                    $display("data_buffer= %h, current size=%0d",data_buffer,up_req_q.size());
                    $display("send a up req, tag=%h, index=%h, id=%h, %t", tag,index,txnid, $realtime);
                    repeat(delay)@(posedge clk);
                end
            end
            3:begin  //index-way conflict
                for(int i=1;i<500;i++)begin
                    tag   = $urandom_range(1,20);
                    index = $urandom_range(1,20);
                    txnid = i%32;
                    @(posedge clk);
                    send_upstream_req(tag,index,txnid);    
                    $display("send a upreq, tag= %h, index= %h, id=%h, %t", tag, index, txnid, $realtime);
                end
            end
            4:begin //read(miss)---read(hit)
                for(int i=1; i<30; i++)begin
                    delay = $urandom_range(10,15);
                    send_upstream_req(i, i, i);
                    $display("send a up req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                    repeat(delay)@(posedge clk);
                end
                #500;
                for(int i=1; i<30; i++)begin
                    delay = $urandom_range(10,15);
                    send_upstream_req(i, i, i);
                    $display("send a up req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                    repeat(delay)@(posedge clk);
                end
                #100;
                for(int i=1; i<30; i++)begin
                    delay = $urandom_range(1, 30);
                    #100;
                    send_downstream_req(i, i, i);
                    $display("i=%d, %t", i, $realtime);
                    @(posedge clk);     
                end
                #500;
                for(int i=1; i<30; i++)begin
                    delay = $urandom_range(10,15);
                    send_upstream_req(i, i, i);
                    $display("send a up req, tag=%h, index=%h, id=%h, %t", i,i,i, $realtime);
                    repeat(delay)@(posedge clk);
                end
            end
            5:begin  //random
                for(int i=1;i<100000;i++)begin
                    tag   = $urandom_range(1,1000);
                    index = $urandom_range(1,200);
                    txnid = i%32;
                    @(posedge clk);
                    send_upstream_req(tag,index,txnid);    
                    $display("send a upreq, tag= %h, index= %h, id=%h, %t", tag, index, txnid, $realtime);
                end
            end
        endcase
        repeat(25000)@(posedge clk);
        $display("up_req_q_size=%0d",up_req_q.size());
        if(up_req_q.size()!=0)$error("there %0d up req not processed!",up_req_q.size());
        $display("PC send %0d up req, receive %0d tx dat",up_req_cnt,tx_dat_cnt);
        $display("PC send %0d tx req, receive %0d rx dat",tx_req_cnt,rx_dat_cnt);
        $display("%0d req hit, %0d req miss",up_req_cnt-tx_req_cnt,tx_req_cnt);
        $display("  Hit rate: %0.2f%%",(up_req_cnt-tx_req_cnt) * 100.0 /up_req_cnt );
        repeat(20000)@(posedge clk);
        $finish;
    end


//========================================================
// rxdata gen
//========================================================
initial begin
    forever begin
        @(posedge clk);
        if(txreq_q.size()>0)begin
                rxdat_delay     = $urandom_range(5, 10);
                repeat(rxdat_delay)@(posedge clk);
                txreq = txreq_q.pop_front();
                txreq_entry_id = txreq_entry_id_q.pop_front();
                downstream_rxdat_vld                            <= 1;
                downstream_rxdat_pld.downstream_rxdat_opcode    <= txreq.opcode;
                downstream_rxdat_pld.downstream_rxdat_txnid     <= txreq.txnid;
                downstream_rxdat_pld.downstream_rxdat_data      <= txreq.addr;
                downstream_rxdat_pld.downstream_rxdat_entry_idx <= txreq_entry_id;
                $display("downstream_rxdat = %h   %t, nid=%0h,remain pkt=%0d",txreq.addr,$realtime,txreq.txnid,txreq_q.size() );
                do begin
                    @(posedge clk);
                end while(downstream_rxdat_rdy!==1'b1);
                rx_dat_cnt++;
                downstream_rxdat_vld                            <=   0;
                downstream_rxdat_pld.downstream_rxdat_opcode    <= 'b0;
                downstream_rxdat_pld.downstream_rxdat_txnid     <= 'b0;
                downstream_rxdat_pld.downstream_rxdat_data      <= 'b0;
                downstream_rxdat_pld.downstream_rxdat_entry_idx <= 'b0;           
        end
    end
end




//========================================================
// checker
//========================================================
    initial begin
        int  txnid_flag=0;
        //int  txdat_duration =0;
        forever begin
            //@(posedge upstream_txdat_vld);
            @(posedge clk);
            if(upstream_txdat_vld===1)begin
                tx_dat_cnt++;
                foreach(up_req[i])begin
                    if(up_req[i].txnid == upstream_txdat_txnid)begin
                        txnid_flag = 1;
                        if(up_req[i].addr !== upstream_txdat_data)begin
                            $error("compare error when txnid=%0d",upstream_txdat_txnid);
                        end else begin
                            $display("txnid %d compare pass",upstream_txdat_txnid);
                        end
                        up_req.delete(i);
                    end
                end
                if(txnid_flag == 0)begin
                    $error("receive txnid=%0d error",upstream_txdat_txnid);
                end 
                else begin
                    txnid_flag = 0;
                end
            end
        end
    end

    icache_top  dut (
        .clk                      (clk                    ),
        .rst_n                    (rst_n                  ),
        .prefetch_enable          (prefetch_enable        ),
        .upstream_txdat_data      (upstream_txdat_data    ),
        .upstream_txdat_vld       (upstream_txdat_vld     ),
        .upstream_txdat_rdy       (upstream_txdat_rdy     ),
        .upstream_txdat_txnid     (upstream_txdat_txnid   ),
        .upstream_rxreq_vld       (upstream_rxreq_vld     ),
        .upstream_rxreq_rdy       (upstream_rxreq_rdy     ),
        .upstream_rxreq_pld       (upstream_rxreq_pld     ),
        .downstream_rxsnp_vld     (downstream_rxsnp_vld   ),
        .downstream_rxsnp_rdy     (downstream_rxsnp_rdy   ),
        .downstream_rxsnp_pld     (downstream_rxsnp_pld   ),
        .downstream_txreq_vld     (downstream_txreq_vld   ),
        .downstream_txreq_rdy     (downstream_txreq_rdy   ),
        .downstream_txreq_pld     (downstream_txreq_pld   ),
        .downstream_txreq_entry_id(downstream_txreq_entry_id),
        .downstream_txrsp_vld     (downstream_txrsp_vld   ),
        .downstream_txrsp_rdy     (downstream_txrsp_rdy   ),
        .downstream_txrsp_opcode  (downstream_txrsp_opcode),
        .downstream_rxdat_vld     (downstream_rxdat_vld   ),
        .downstream_rxdat_rdy     (downstream_rxdat_rdy   ),
        .downstream_rxdat_pld     (downstream_rxdat_pld   ),
        .prefetch_req_vld         (1'b0                   ),
        .prefetch_req_pld         ('b0                    ),
        .pref_to_mshr_req_rdy     (pref_to_mshr_req_rdy));
		

    initial begin
        if($test$plusargs("WAVE")) begin
            $fsdbDumpfile("wave.fsdb");
            $fsdbDumpvars("+all");
            //$fsdbDumpMDA;
            $fsdbDumpon;
    	end
    end

//========================================================
// hit.miss counter
//========================================================
    int last_up_req_cnt = 0;  
    initial begin
        forever begin
            @(posedge clk);
            if (up_req_cnt > last_up_req_cnt) begin
                global_up_req_cnt++;
                local_up_req_cnt++;
            end
            if (downstream_txreq_vld === 1) begin
                local_tx_req_cnt++;
            end
            if (local_up_req_cnt == 1000) begin
                $display("last1000req %0d - %0d: hit %0d, miss %0d", 
                         global_up_req_cnt - 1000, global_up_req_cnt - 1, 
                         local_up_req_cnt - local_tx_req_cnt, local_tx_req_cnt);
                local_up_req_cnt = 0;
                local_tx_req_cnt = 0;
            end
            last_up_req_cnt = up_req_cnt;
        end
    end

//========================================================
// downstream txreq counter
//========================================================
    initial begin
        forever begin
            @(posedge clk);
            if(downstream_txreq_vld===1)begin
                tx_req_cnt++;
                txreq_q.push_back(downstream_txreq_pld);
                txreq_entry_id_q.push_back(downstream_txreq_entry_id);
            end
        end
    end


endmodule