`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2022 06:03:16 PM
// Design Name: 
// Module Name: Data_Chunk
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


module Data_Chunk #(
	 parameter MEM_SIZE = 128	//Bytes
	,parameter BUS_SIZE = 16	//Bytes
	,parameter PREFIX_SUM_SIZE = 16	//bits	
)(
	 input rst_i
	,input clk_i
	,input [BUS_SIZE-1:0] wr_sparsemap_i
	,input [BUS_SIZE-1:0][7:0] wr_nonzero_data_i 	//Bandwidth = 128 Bytes
	,input wr_valid_i
	,input refresh_mem_i
	,output wr_ready_o

	,input [$clog2(MEM_SIZE):0] rd_addr_i
	,output [7:0] rd_data_o
	,output rd_ready_o

	,input [$clog2(MEM_SIZE/PREFIX_SUM_SIZE)-1:0] rd_sparsemap_addr_i
	,output logic [PREFIX_SUM_SIZE-1:0] rd_sparsemap_o	
);
	
	logic [MEM_SIZE-1:0] mem_sparsemap_r;
	//The Data array should start from 1
	logic [MEM_SIZE:1][7:0] mem_nonzero_data_r;

	localparam DATA_IN_CYCLE_NUM = MEM_SIZE/BUS_SIZE;
	logic [$clog2(DATA_IN_CYCLE_NUM)-1:0] wr_count_r;

	reg state_wr_mem_r;

	logic wr_fire_w;

	assign wr_fire_w = wr_valid_i && wr_ready_o;

	always_ff @(posedge clk_i) begin
		if (rst_i)	state_wr_mem_r <= #1 1'b1;
		else begin
			if (refresh_mem_i)
				state_wr_mem_r <= #1 1'b1;
			else if (wr_fire_w && (wr_count_r == DATA_IN_CYCLE_NUM-1))
				state_wr_mem_r <= #1 1'b0;
		end
	end

	// Write data
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			wr_count_r <= #1 {($clog2(DATA_IN_CYCLE_NUM)){1'b0}};
		end
		else if (wr_fire_w) begin
			wr_count_r <= #1 wr_count_r + 1'b1;
		end
	end

	// Write data
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			mem_sparsemap_r <= #1 {MEM_SIZE{1'b0}};
			mem_nonzero_data_r <= #1 {MEM_SIZE{8'h00}};
		end
		else if (wr_fire_w) begin
			for (integer i=0; i<DATA_IN_CYCLE_NUM; i=i+1) begin
				if (wr_count_r == i) begin
					mem_sparsemap_r[BUS_SIZE*i +: BUS_SIZE] <= #1 wr_sparsemap_i;
					mem_nonzero_data_r[BUS_SIZE*i +: BUS_SIZE] <= #1 wr_nonzero_data_i;
				end
			end
		end
	end

	// Read Sparsemap
	always_comb begin
		for (integer i=0; i<(MEM_SIZE/PREFIX_SUM_SIZE); i = i+1) begin
			if (rd_sparsemap_addr_i == i)
				rd_sparsemap_o = mem_sparsemap_r[PREFIX_SUM_SIZE*i +: PREFIX_SUM_SIZE];
		end
	end

	assign wr_ready_o = state_wr_mem_r;
	assign rd_ready_o = !state_wr_mem_r;
	// Read Nonzero data
	assign rd_data_o = mem_nonzero_data_r[rd_addr_i];

endmodule
