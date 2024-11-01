module sync_fifo 
    #(
        parameter FIFO_WIDTH       = 10'd4,
        //parameter FIFO_WIDTH_BIT   = 10'd2,
        parameter FIFO_DEPTH       = 10'd8,
        parameter FIFO_DEPTH_BIT   = 10'd3
    )
    (
        input  logic                            clk         ,
        input  logic                            rst_n       ,
        input  logic                            w_en        ,
        input  logic                            r_en        ,
        input  logic [FIFO_WIDTH-1:0]           data_write  ,

        output logic                            flag_full   ,
        output logic                            flag_empty  ,
        output logic [FIFO_WIDTH-1:0]           data_read
    );
    
    logic [FIFO_DEPTH_BIT   :0]                 count       ; 
    logic [FIFO_DEPTH_BIT   :0]                 index       ;
    logic [FIFO_DEPTH_BIT-1 :0]                 write_addr  ; 
    logic [FIFO_DEPTH_BIT-1 :0]                 read_addr   ; 
    logic [FIFO_WIDTH-1     :0]                 memory [FIFO_DEPTH-1:0]; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr <= 0;
            for(index=0; index<=FIFO_DEPTH-1; index=index+1'b1)begin
                memory[index] <= 0;
            end
        end
        else if (w_en && (!flag_full)) begin
            memory[write_addr] <= data_write;
            write_addr         <= write_addr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            data_read  <= 0;
            read_addr  <= 0;
        end
        else if (r_en && (!flag_empty)) begin
            data_read  <= memory[read_addr];
            read_addr <= read_addr + 1'b1;
        end
    end
   
    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            count <= 0;
        else if( (w_en && (!flag_full)) &&  !(r_en && (!flag_empty)) )
            count <= count + 1'b1;
        else if( (r_en && (!flag_empty)) &&  !(w_en && (!flag_full)) ) 
            count <= count - 1'b1;
        else
            count <= count;
    end

    assign flag_empty = (count==0);
    //assign flag_full  = (count[FIFO_DEPTH_BIT]== 1'b1 && count[FIFO_DEPTH_BIT-1:0]==0);
    assign flag_full  = 0;

endmodule







//module sync_fifo # (
//    parameter integer unsigned  DATA_WIDTH = 8,					
//    parameter integer unsigned  ADDR_WIDTH = 8
//)(
//	input  logic 							clk     ,		
//	input  logic 							rst_n   ,							
//	input  logic 							wr_en   ,		
//	input  logic 							rd_en   ,		
//	input  logic [DATA_WIDTH-1:0]	        data_in ,	
//	output logic [DATA_WIDTH-1:0]	        data_out,	
//	output logic 						    full    ,		
//	output logic 						    empty 		
//);
//
//parameter FIFO_DEPTH = (1 << ADDR_WIDTH); 	
//
//
//logic  [ADDR_WIDTH-1:0] 	wr_pointer;		
//logic  [ADDR_WIDTH-1:0] 	rd_pointer;		
//logic  [ADDR_WIDTH  :0] 	status_cnt;		
//logic  [DATA_WIDTH-1:0]	    fifo [0:FIFO_DEPTH-1];	
//
//
////logic wr_en_r;
////logic rd_en_r;
////
////always@(posedge clk or negedge rst_n) begin
////	if(!rst_n) begin
////		wr_en_r <= 1'b0;
////		rd_en_r <= 1'b0;
////	end
////	
////	else begin
////		wr_en_r <= wr_en;
////      rd_en_r <= rd_en;
////	end
////	
////end	
//
//always@(posedge clk or negedge rst_n) begin
//	if(!rst_n)
//		wr_pointer <= 0;
//	else if(wr_en && (status_cnt != (FIFO_DEPTH))) 
//		wr_pointer <= wr_pointer + 1;
//end
//
//always@(posedge clk or negedge rst_n) begin
//	if(!rst_n)
//		rd_pointer <= 0;	
//	else if(rd_en && (status_cnt != 0))
//		rd_pointer <= rd_pointer + 1;
//end
//
//
//logic status_rd = rd_en && !wr_en && (status_cnt != 0);
//logic status_wr = wr_en && !rd_en && (status_cnt != (FIFO_DEPTH));	
//
//always@(posedge clk or negedge rst_n) begin
//	if(!rst_n)
//		status_cnt <= 0;
//	else if (status_rd)
//		status_cnt <= status_cnt - 1;
//	else if (status_wr)
//		status_cnt <= status_cnt + 1;	
//	else
//		status_cnt <= status_cnt;	
//end
//
//always@(posedge clk) begin	
//	if(wr_en && !full)
//		fifo[wr_pointer] <= data_in;
//end
//
//logic [DATA_WIDTH-1:0] data_out_r;
//always@(posedge clk) begin	
//	if(rd_en)
//		data_out_r <= fifo[rd_pointer];	
//end
//
//assign data_out = data_out_r;
//
//assign full = (status_cnt > (FIFO_DEPTH-1));
//assign empty = (status_cnt == 0);
//
//endmodule