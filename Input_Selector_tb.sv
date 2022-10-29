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

parameter CHUNK_SIZE = 128;	//Bytes
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
logic [7:0] fil_data_o;
logic data_valid_o;
logic sub_chunk_end_o;
logic ifm_wr_ready_o;
logic fil_wr_ready_o;
logic [OUTPUT_BUF_SIZE-1:0] out_buf_dat_o;


localparam DATA_IN_CYCLE_NUM = CHUNK_SIZE/BUS_SIZE;

logic [CHUNK_SIZE-1:0][7:0] ifm_sram_non_zero_data_r = {CHUNK_SIZE{8'h00}};
logic [CHUNK_SIZE-1:0] ifm_sram_sparse_map_r ;
logic [BUS_SIZE-1:0][7:0] ifm_non_zero_data_r;
logic [BUS_SIZE-1:0] ifm_sparse_map_r ;
logic ifm_wr_valid_i_r;
logic [CHUNK_SIZE-1:0][7:0] fil_sram_non_zero_data_r = {CHUNK_SIZE{8'h00}};
logic [CHUNK_SIZE-1:0] fil_sram_sparse_map_r ;
logic [BUS_SIZE-1:0][7:0] fil_non_zero_data_r;
logic [BUS_SIZE-1:0] fil_sparse_map_r ;
logic fil_wr_valid_i_r;

logic [$clog2(OUTPUT_BUF_NUM)-1:0] acc_buf_sel_r;
logic [$clog2(OUTPUT_BUF_NUM)-1:0] out_buf_sel_r;


Compute_Unit_Top #(
	 .CHUNK_SIZE(CHUNK_SIZE)
	,.BUS_SIZE(BUS_SIZE)
	,.PREFIX_SUM_SIZE(PREFIX_SUM_SIZE)
	,.OUTPUT_BUF_SIZE(OUTPUT_BUF_SIZE)
	,.OUTPUT_BUF_NUM(OUTPUT_BUF_NUM)
) u_Compute_Unit_Top (
	 .rst_i(RESET)
	,.clk_i(CLK)
	,.ifm_sparsemap_i(ifm_sparse_map_r)
	,.ifm_nonzero_data_i(ifm_non_zero_data_r)
	,.ifm_chunk_wr_valid_i(ifm_wr_valid_i_r)	
	,.ifm_wr_ready_o
	,.fil_sparsemap_i(fil_sparse_map_r)
	,.fil_nonzero_data_i(fil_non_zero_data_r)
	,.fil_chunk_wr_valid_i(fil_wr_valid_i_r)	
	,.fil_wr_ready_o

	,.sub_chunk_end_o

	,.acc_buf_sel_i(acc_buf_sel_r)
	,.out_buf_sel_i(out_buf_sel_r)
	,.out_buf_dat_o
);

//Stimulate
//logic [$clog2(CHUNK_SIZE):0] j_0=1;
//logic [$clog2(CHUNK_SIZE):0] j_1=1;

task ifm_mem_gen();
	integer i;
	logic [$clog2(CHUNK_SIZE):0] j=0;
	logic [7:0] data;
	integer low_bound = $urandom_range(10,3);

	for (i=0; i<CHUNK_SIZE; i=i+1) begin
		data = $urandom_range(256,0);

		if (data > 10*low_bound) begin
			ifm_sram_non_zero_data_r[j] = data;
			ifm_sram_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			ifm_sram_sparse_map_r[i] = 0;
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

		assign ifm_sparse_map_r = ifm_sram_sparse_map_r[BUS_SIZE*k +: BUS_SIZE];
		assign ifm_non_zero_data_r = ifm_sram_non_zero_data_r[BUS_SIZE*k +: BUS_SIZE];

task fil_mem_gen();
	integer i;
	logic [$clog2(CHUNK_SIZE):0] j=0;
	logic [7:0] data;

	for (i=0; i<CHUNK_SIZE; i=i+1) begin
		data = $urandom_range(256,0);

		if (data > 50) begin
			fil_sram_non_zero_data_r[j] = data;
			fil_sram_sparse_map_r[i] = 1;
			j = j+1;
		end
		else begin
			fil_sram_sparse_map_r[i] = 0;
		end
	end
	#1;
	fil_wr_valid_i_r = 1'b1;
endtask

integer n=0;

task fil_input_gen();
	fil_mem_gen();

	repeat(DATA_IN_CYCLE_NUM) @(posedge (fil_wr_valid_i_r && fil_wr_ready_o && CLK && !RESET)) begin
		#1;
		n = n+1;
	end
	n=0;

endtask

		assign fil_sparse_map_r = fil_sram_sparse_map_r[BUS_SIZE*n +: BUS_SIZE];
		assign fil_non_zero_data_r = fil_sram_non_zero_data_r[BUS_SIZE*n +: BUS_SIZE];

initial begin
	fil_input_gen();
end

initial begin
	acc_buf_sel_r = 0;
	out_buf_sel_r = 0;
	ifm_input_gen();
	#cyc;
	ifm_input_gen();
	//Generate data
	repeat(10) @(negedge sub_chunk_end_o) begin
		acc_buf_sel_r = acc_buf_sel_r + 1;
		out_buf_sel_r = out_buf_sel_r + 1;
		ifm_input_gen();
	end
end

endmodule
