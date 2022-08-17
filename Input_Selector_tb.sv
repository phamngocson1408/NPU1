`timescale 1ns / 1ps
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


module Input_Selector_tb(

    );

parameter MEM_SIZE = 128;	//Bytes
parameter BUS_SIZE = 8;		//Bytes
parameter PREFIX_SUM_SIZE = 8;	//bits
parameter OUTPUT_BUF_SIZE = 32; // bits
parameter OUTPUT_BUF_NUM = 32; 

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
	RESET = 0;
end

//Instance
logic [7:0] ifm_data_o;
logic [7:0] filter_data_o;
logic data_valid_o;
logic chunk_end_o;
logic ifm_wr_ready_o;
logic filter_wr_ready_o;
logic [OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;


localparam DATA_IN_CYCLE_NUM = MEM_SIZE/BUS_SIZE;

logic [MEM_SIZE-1:0][7:0] mem_ifm_non_zero_data_r = {MEM_SIZE{8'h00}};
logic [MEM_SIZE-1:0] mem_ifm_sparse_map_r ;
logic [BUS_SIZE-1:0][7:0] ifm_non_zero_data_r;
logic [BUS_SIZE-1:0] ifm_sparse_map_r ;
logic ifm_wr_valid_i_r;
logic [MEM_SIZE-1:0][7:0] mem_filter_non_zero_data_r = {MEM_SIZE{8'h00}};
logic [MEM_SIZE-1:0] mem_filter_sparse_map_r ;
logic [BUS_SIZE-1:0][7:0] filter_non_zero_data_r;
logic [BUS_SIZE-1:0] filter_sparse_map_r ;
logic filter_wr_valid_i_r;

logic [$clog2(OUTPUT_BUF_NUM)-1:0] acc_buf_sel_r;
logic [$clog2(OUTPUT_BUF_NUM)-1:0] out_buf_sel_r;


Compute_Unit_Top #(
	 .MEM_SIZE(MEM_SIZE)
	,.BUS_SIZE(BUS_SIZE)
	,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	,.OUTPUT_BUF_NUM(OUTPUT_BUF_NUM)
) u_Compute_Unit_Top (
	 .rst_i(RESET)
	,.clk_i(CLK)
	,.ifm_sparsemap_i(ifm_sparse_map_r)
	,.ifm_nonzero_data_i(ifm_non_zero_data_r)
	,.ifm_wr_valid_i(ifm_wr_valid_i_r)	
	,.ifm_wr_ready_o
	,.filter_sparsemap_i(filter_sparse_map_r)
	,.filter_nonzero_data_i(filter_non_zero_data_r)
	,.filter_wr_valid_i(filter_wr_valid_i_r)	
	,.filter_wr_ready_o

	,.chunk_end_o

	,.acc_buf_sel_i(acc_buf_sel_r)
	,.out_buf_sel_i(out_buf_sel_r)
	,.out_buf_dat_o
);

//Stimulate
//logic [$clog2(MEM_SIZE):0] j_0=1;
//logic [$clog2(MEM_SIZE):0] j_1=1;

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
	#1;
	ifm_wr_valid_i_r = 1'b1;
endtask

integer k=0;

task ifm_input_gen();
//	integer k=0;
	ifm_mem_gen();

	repeat(DATA_IN_CYCLE_NUM) @(posedge (ifm_wr_valid_i_r && ifm_wr_ready_o && CLK && !RESET)) begin
		#1;
		k = k+1;
	end
	k=0;

endtask

		assign ifm_sparse_map_r = mem_ifm_sparse_map_r[BUS_SIZE*k +: BUS_SIZE];
		assign ifm_non_zero_data_r = mem_ifm_non_zero_data_r[BUS_SIZE*k +: BUS_SIZE];

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
	#1;
	filter_wr_valid_i_r = 1'b1;
endtask

integer n=0;

task filter_input_gen();
	filter_mem_gen();

	repeat(DATA_IN_CYCLE_NUM) @(posedge (filter_wr_valid_i_r && filter_wr_ready_o && CLK && !RESET)) begin
		#1;
		n = n+1;
	end
	n=0;

endtask

		assign filter_sparse_map_r = mem_filter_sparse_map_r[BUS_SIZE*n +: BUS_SIZE];
		assign filter_non_zero_data_r = mem_filter_non_zero_data_r[BUS_SIZE*n +: BUS_SIZE];

initial begin
	filter_input_gen();
end

initial begin
	acc_buf_sel_r = 0;
	out_buf_sel_r = 0;
	ifm_input_gen();
	#cyc;
	ifm_input_gen();
	//Generate data
	repeat(10) @(negedge chunk_end_o) begin
		acc_buf_sel_r = acc_buf_sel_r + 1;
		out_buf_sel_r = out_buf_sel_r + 1;
		ifm_input_gen();
	end
end

endmodule
