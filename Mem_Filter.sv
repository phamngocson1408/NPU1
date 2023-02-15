`include "Global_Include.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2022 02:36:59 PM
// Design Name: 
// Module Name: Mem_Filter
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


module Mem_Filter #(
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i
	,input wr_valid_i
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] wr_dat_count_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] wr_chunk_count_i

	,output [`BUS_SIZE-1:0] rd_sparsemap_o
	,output [`BUS_SIZE-1:0][7:0] rd_nonzero_data_o
	,input [$clog2(`WR_DAT_CYC_NUM)-1:0] rd_dat_count_i
	,input [$clog2(`SRAM_FILTER_NUM)-1:0] rd_chunk_count_i
);

	logic [`SRAM_FILTER_NUM-1:0][`CHUNK_SIZE-1:0] mem_sparsemap_r;
	logic [`SRAM_FILTER_NUM-1:0][`CHUNK_SIZE-1:0][7:0] mem_nonzero_data_r;

	// Write data
	logic gated_clk_lat;
	always_latch begin
		if (!clk_i) begin
			gated_clk_lat <= (rst_i || wr_valid_i);
		end
	end
	wire gated_clk_w = clk_i && gated_clk_lat;
	always_ff @(posedge gated_clk_w) begin
		if (rst_i) begin
			mem_sparsemap_r <= {(`SRAM_FILTER_NUM*`CHUNK_SIZE){1'b0}};
			mem_nonzero_data_r <= {(`SRAM_FILTER_NUM*`CHUNK_SIZE){8'h00}};
		end
		else if (wr_valid_i) begin
			for (integer i=0; i<`SRAM_FILTER_NUM; i=i+1) begin 
				for (integer j=0; j<`WR_DAT_CYC_NUM; j=j+1) begin
					if ((wr_chunk_count_i == i) && (wr_dat_count_i == j)) begin
						mem_sparsemap_r[i][`BUS_SIZE*j +: `BUS_SIZE] <= wr_sparsemap_i;
						mem_nonzero_data_r[i][`BUS_SIZE*j +: `BUS_SIZE] <= wr_nonzero_data_i;
					end
				end
			end
		end
	end

	assign rd_nonzero_data_o = mem_nonzero_data_r[rd_chunk_count_i][`BUS_SIZE*rd_dat_count_i +: `BUS_SIZE];
	assign rd_sparsemap_o = mem_sparsemap_r[rd_chunk_count_i][`BUS_SIZE*rd_dat_count_i +: `BUS_SIZE];

endmodule

