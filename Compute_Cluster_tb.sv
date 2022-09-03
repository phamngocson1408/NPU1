`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2022 03:58:21 PM
// Design Name: 
// Module Name: Input_Selector_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module Compute_Cluster_tb(

    );

parameter MEM_SIZE = 128;	//Bytes
parameter BUS_SIZE = 8;		//Bytes
parameter PREFIX_SUM_SIZE = `PREFIX_SUM_SIZE;	//bits
parameter OUTPUT_BUF_SIZE = 32; // bits
parameter OUTPUT_BUF_NUM = 32; 
parameter COMPUTE_UNIT_NUM = 32; 

parameter cyc = 10;

//CLock generate
reg CLK;
initial begin
	CLK=0;
	#(cyc/2);
	while (1) begin
		CLK = ~CLK;
		#(cyc/2);
	end
end

//Reset generate
reg RESET;
initial begin
	RESET = 1;
	#(cyc*50);
	@(posedge CLK);
	#1;
	RESET = 0;
end

//Instance
localparam DATA_IN_CYCLE_NUM = MEM_SIZE/BUS_SIZE;

logic [MEM_SIZE-1:0][7:0] mem_ifm_non_zero_data_r = {MEM_SIZE{8'h00}};
logic [MEM_SIZE-1:0] mem_ifm_sparse_map_r ;

logic [BUS_SIZE-1:0][7:0] ifm_nonzero_data_r;
logic [BUS_SIZE-1:0] ifm_sparse_map_r ;
logic ifm_wr_valid_r;
logic [$clog2(MEM_SIZE/BUS_SIZE)-1:0] ifm_wr_count_r ;
logic ifm_wr_sel_r;
logic ifm_rd_sel_r;

logic [MEM_SIZE-1:0][7:0] mem_filter_non_zero_data_r = {MEM_SIZE{8'h00}};
logic [MEM_SIZE-1:0] mem_filter_sparse_map_r ;

logic [BUS_SIZE-1:0][7:0] filter_nonzero_data_r;
logic [BUS_SIZE-1:0] filter_sparse_map_r ;
logic filter_wr_valid_r;
logic [$clog2(MEM_SIZE/BUS_SIZE)-1:0] filter_wr_count_r ;
logic filter_wr_sel_r;
logic filter_rd_sel_r;
logic [$clog2(OUTPUT_BUF_NUM)-1:0] filter_wr_order_sel_r;

logic init_r;
logic chunk_start_r;
logic chunk_end_o;

logic [$clog2(OUTPUT_BUF_NUM)-1:0] acc_buf_sel_r;
logic [$clog2(OUTPUT_BUF_NUM)-1:0] out_buf_sel_r;
logic [$clog2(COMPUTE_UNIT_NUM)-1:0] com_unit_out_buf_sel_r = 0;
//logic [COMPUTE_UNIT_NUM-1:0][OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;
logic [OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;


Compute_Cluster #(
	 .MEM_SIZE(MEM_SIZE)
	,.BUS_SIZE(BUS_SIZE)
	,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	,.OUTPUT_BUF_NUM(OUTPUT_BUF_NUM)
	,.COMPUTE_UNIT_NUM(COMPUTE_UNIT_NUM)
) u_Compute_Cluster (
	 .rst_i(RESET)
	,.clk_i(CLK)

	,.ifm_sparsemap_i(ifm_sparse_map_r)
	,.ifm_nonzero_data_i(ifm_nonzero_data_r)
	,.ifm_wr_valid_i(ifm_wr_valid_r)	
	,.ifm_wr_count_i(ifm_wr_count_r)	
	,.ifm_wr_sel_i(ifm_wr_sel_r)	
	,.ifm_rd_sel_i(ifm_rd_sel_r)	

	,.filter_sparsemap_i(filter_sparse_map_r)
	,.filter_nonzero_data_i(filter_nonzero_data_r)
	,.filter_wr_valid_i(filter_wr_valid_r)	
	,.filter_wr_count_i(filter_wr_count_r)	
	,.filter_wr_sel_i(filter_wr_sel_r)	
	,.filter_rd_sel_i(filter_rd_sel_r)	
	,.filter_wr_order_sel_i(filter_wr_order_sel_r)	

	,.init_i(init_r)
	,.chunk_start_i(chunk_start_r)
	,.chunk_end_o

	,.acc_buf_sel_i(acc_buf_sel_r)
	,.out_buf_sel_i(out_buf_sel_r)
	,.com_unit_out_buf_sel_i(com_unit_out_buf_sel_r)
	,.out_buf_dat_o
);

task ifm_mem_gen();
	integer i;
	logic [$clog2(MEM_SIZE):0] j=0;
	logic [7:0] data;
	integer low_bound = $urandom_range(10,3);

	for (i=0; i<MEM_SIZE; i=i+1) begin
		data = $urandom_range(256,0);

		if (data > 10*low_bound) begin
			mem_ifm_non_zero_data_r[j] = data;
			mem_ifm_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_ifm_sparse_map_r[i] = 0;
		end
	end
endtask

task ifm_input_gen();
	ifm_mem_gen();
//	#1;
	ifm_wr_valid_r = 1'b1;
	ifm_wr_count_r = 0;

	repeat(DATA_IN_CYCLE_NUM) @(posedge (CLK && !RESET)) begin
		#1;
		ifm_wr_count_r = ifm_wr_count_r+1;
	end

//	#1;
	ifm_wr_valid_r = 1'b0;
	ifm_wr_count_r = 0;
endtask
assign ifm_sparse_map_r = mem_ifm_sparse_map_r[BUS_SIZE*ifm_wr_count_r +: BUS_SIZE];
assign ifm_nonzero_data_r = mem_ifm_non_zero_data_r[BUS_SIZE*ifm_wr_count_r +: BUS_SIZE];

task filter_mem_gen();
	integer i;
	logic [$clog2(MEM_SIZE):0] j=0;
	logic [7:0] data;

	for (i=0; i<MEM_SIZE; i=i+1) begin
		data = $urandom_range(256,0);

		if (data > 50) begin
			mem_filter_non_zero_data_r[j] = data;
			mem_filter_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			mem_filter_sparse_map_r[i] = 0;
		end
	end
endtask

task filter_input_gen();
	filter_mem_gen();
//	#1;
	filter_wr_valid_r = 1'b1;
	filter_wr_count_r = 0;

	repeat(DATA_IN_CYCLE_NUM) @(posedge (CLK && !RESET)) begin
		#1;
		filter_wr_count_r = filter_wr_count_r+1;
	end

//	#1;
	filter_wr_valid_r = 1'b0;
	filter_wr_count_r = 0;
endtask

assign filter_sparse_map_r = mem_filter_sparse_map_r[BUS_SIZE*filter_wr_count_r +: BUS_SIZE];
assign filter_nonzero_data_r = mem_filter_non_zero_data_r[BUS_SIZE*filter_wr_count_r +: BUS_SIZE];

initial begin
	 @(posedge (CLK && !RESET)) #1;
	init_r = 1'b1;
	filter_wr_sel_r = 1'b0;
	filter_wr_order_sel_r = 0;
	repeat(COMPUTE_UNIT_NUM) begin
		filter_input_gen();
		filter_wr_order_sel_r = filter_wr_order_sel_r + 1;
	end

	ifm_wr_sel_r = 1'b0;
	ifm_input_gen();


	acc_buf_sel_r = 0;
	out_buf_sel_r = 0;
	init_r = 1'b0;

	ifm_rd_sel_r = 1'b0;
	filter_rd_sel_r = 1'b0;

	ifm_wr_sel_r = 1'b1;
	ifm_input_gen();

//	repeat(10) @(posedge chunk_end_o) begin
//		@(posedge CLK) #1;
//		acc_buf_sel_r = acc_buf_sel_r + 1;
//		out_buf_sel_r = out_buf_sel_r + 1;
//		ifm_rd_sel_r = ~ifm_rd_sel_r;
//		ifm_wr_sel_r = ~ifm_wr_sel_r;
//	end
end

always @(posedge CLK) begin
	if (chunk_end_o) begin
		#1;
		acc_buf_sel_r = acc_buf_sel_r + 1;
		out_buf_sel_r = out_buf_sel_r + 1;
		ifm_rd_sel_r = ~ifm_rd_sel_r;
		ifm_wr_sel_r = ~ifm_wr_sel_r;
	end
end

//initial begin
//	repeat(10) @(posedge chunk_end_o) begin
//		@(posedge CLK) #1; ifm_input_gen();
//	end
//end

always @(posedge CLK) begin
	if (chunk_end_o) begin
		#1; ifm_input_gen();
	end
end

//initial begin
//	chunk_start_r = 1'b0;
//
//	repeat(10) @(posedge chunk_end_o) begin
//		@(posedge CLK) #1 ; chunk_start_r = 1'b1;
//		@(posedge CLK) #1 ; chunk_start_r = 1'b0;
//	end
//end

always @(posedge CLK) begin
	if (RESET) begin
		#1; chunk_start_r = 1'b0;
	end
	else if (chunk_end_o) begin
		#1; chunk_start_r = 1'b1;
	end
	else if (chunk_start_r) begin
		#1; chunk_start_r = 1'b0;
	end
	else begin
		#1; chunk_start_r = 1'b0;
	end
end

integer check_int = 0;
always @(posedge CLK) begin
	if (chunk_end_o) begin
		#1; check_int = check_int + 1;
		if (check_int == 32) $finish;
	end
end


endmodule
