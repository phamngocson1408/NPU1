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
	 localparam int CHUNK_SIZE = `MEM_SIZE
 	,localparam int FILTER_NUM = CHUNK_SIZE / `CHANNEL_NUM
	,localparam int OUTPUT_NUM = (FILTER_NUM <= `OUTPUT_BUF_NUM) ? FILTER_NUM : `OUTPUT_BUF_NUM
 	,localparam int IFM_NUM = FILTER_NUM + OUTPUT_NUM
	,localparam int PARAM_WR_DAT_CYC_NUM = `MEM_SIZE/`BUS_SIZE
)(
	 input rst_i
	,input clk_i

	,input [`BUS_SIZE-1:0] wr_sparsemap_i
	,input [`BUS_SIZE-1:0][7:0] wr_nonzero_data_i
	,input wr_valid_i
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] wr_dat_count_i
	,input [$clog2(FILTER_NUM)-1:0] wr_chunk_count_i

	,output [`BUS_SIZE-1:0] rd_sparsemap_o
	,output [`BUS_SIZE-1:0][7:0] rd_nonzero_data_o
	,input [$clog2(PARAM_WR_DAT_CYC_NUM)-1:0] rd_dat_count_i
	,input [$clog2(FILTER_NUM)-1:0] rd_chunk_count_i
);

	logic [FILTER_NUM-1:0][CHUNK_SIZE-1:0] mem_sparsemap_r;
	logic [FILTER_NUM-1:0][CHUNK_SIZE-1:0][7:0] mem_nonzero_data_r;

	// Write data
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			mem_sparsemap_r <= {(FILTER_NUM*CHUNK_SIZE){1'b0}};
			mem_nonzero_data_r <= {(FILTER_NUM*CHUNK_SIZE){8'h00}};
		end
		else if (wr_valid_i) begin
			for (integer i=0; i<FILTER_NUM; i=i+1) begin 
				for (integer j=0; j<PARAM_WR_DAT_CYC_NUM; j=j+1) begin
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

